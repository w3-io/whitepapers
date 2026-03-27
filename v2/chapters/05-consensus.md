# Consensus

## BOSCO

W3.io uses a single Byzantine fault-tolerant consensus algorithm for all protocol-level agreement. The protocol's consensus is inspired by BOSCO [@song2008bosco] (which demonstrated that BFT agreement can complete in a single communication step under favorable conditions) and builds on the foundational work of practical BFT [@castro1999pbft]. W3.io's implementation extends these ideas into a leader-based, view-change-capable protocol optimized for the per-step consensus pattern of workflow execution.

The protocol tolerates up to f faulty or adversarial validators in a committee of 3f+1 members. In a 10-member committee, up to 3 members can be Byzantine (offline, malicious, or sending conflicting messages) and the protocol still reaches correct consensus.

The consensus protocol operates in three phases.

**Propose.** The committee leader constructs a proposal and broadcasts it to all committee members. The proposal contains the value being decided on (which validator should run a step, what the attestation set looks like, which receipts to include in an epoch) along with the leader's identity and a round number. The leader is selected deterministically from the committee using the round number, so all honest members agree on who the current leader is.

**Vote.** Each committee member receives the proposal, validates it against their local state (does the proposed runner exist in the validator set? does the receipt hash match what they received via gossipsub?), and broadcasts a vote. A vote either confirms the proposal or rejects it. Votes are signed and include the round number to prevent cross-round replay. Each member collects votes from other members as they arrive over P2P.

**Decide.** When a member has collected 2f+1 matching votes for the same proposal in the same round, the decision is final. The member applies the decision locally (advance the state machine, record the attestation, close the epoch). The 2f+1 threshold guarantees that any two quorums overlap by at least one honest member, which means two conflicting decisions in the same round are impossible.

**View change.** If the leader fails to propose within a configurable timeout, any member can initiate a view change. The round number increments, a new leader is selected deterministically, and the protocol restarts from the Propose phase with the new leader. This is automatic. No operator intervention is needed. A faulty leader costs one timeout period (typically seconds), not a stalled workflow.

View changes are critical for liveness. Without them, a single offline or malicious leader could block all workflow execution indefinitely. With them, the worst case is a brief delay while leadership rotates. The protocol cycles through leaders until it finds one that responds.

The consensus protocol is not a novel construction. It follows the established BFT pattern found in production systems across the blockchain industry [@castro1999pbft], extended with ideas from BOSCO's one-step optimization for the common case where no faults or contention are present [@song2008bosco]. W3.io's implementation is 2,720 lines of Rust [@matsakis2014rust], tested under multi-node deployments with injected Byzantine faults including equivocating leaders, message delays, and partitioned networks.

W3.io chose a single consensus algorithm rather than offering pluggable consensus per workflow. This is deliberate. Pluggable consensus adds complexity without proportional benefit. The security properties of the network depend on one well-tested algorithm, not a menu of options with varying guarantees. The same consensus protocol is used everywhere agreement is needed. The contexts differ, but the mechanism is the same.

## The Workflow State Machine

When a workflow is triggered, W3.io's consensus engine drives it through a four-state machine. Each state represents a phase of the workflow step lifecycle, and each transition requires committee agreement.

**State 1: Awaiting Trigger.** A trigger event arrives: a cron tick, an RPC call, a chain event, or an oracle update. The protocol must first confirm that the trigger is legitimate. For RPC triggers, this means verifying the caller's signature against the namespace's authorization policy. For chain events, this means confirming the event actually occurred on-chain through a monitor group (a small committee of validators assigned to watch that specific event type).

Once the trigger is confirmed, a workflow committee is selected from the active validator set using the deterministic shuffle described below. The committee members receive the trigger evidence and the workflow definition. The run begins.

**State 2: Awaiting Step Runner Proposals.** For each step in the workflow, the committee must agree on which validator executes it. The committee leader examines the eligible validators (those online, with sufficient capability, and not already overloaded) and proposes a runner. Committee members verify that the proposed runner is eligible and vote to confirm.

If the leader fails to propose within the round timeout, view change rotates leadership. If the selected runner accepts but then fails to return a result within the step timeout, the committee marks the runner as failed and the leader proposes a new runner. After M consecutive runner failures for the same step (configurable, default 3), the workflow itself is marked as failed. This prevents infinite retry loops on steps that are fundamentally broken.

**State 3: Awaiting Step Execution.** The selected runner executes the step using the execution backend (Section 4). This is the only phase where actual computation happens. The runner pulls the container image (if needed), injects the step's inputs and environment, runs the command, and captures the outputs.

When execution completes, the runner broadcasts the result to the committee: the step's outputs, the execution duration, the exit code, and a hash of the produced workflow block. The workflow block contains the step's inputs, outputs, the runner's identity, and the previous block's hash, forming a per-run hashchain.

**State 4: Awaiting Step Attestation.** Committee members independently assess the runner's result. Each member produces an attestation with one of three values:

- **Confirmed**: the result appears correct based on the member's local validation
- **Rejected**: the result is inconsistent with what the member expected (for example, the output hash doesn't match a deterministic recomputation)
- **Indeterminate**: the member cannot determine correctness (for example, the step interacted with an external API that the member cannot independently verify)

The committee runs BOSCO to agree on the canonical attestation set. A deterministic decision rule produces the final verdict from the agreed assessments. If the majority confirmed, the step passes and the state machine advances to State 2 for the next step. If the majority rejected, the step fails and the workflow's failure handling logic determines whether execution continues.

When all steps complete, the workflow produces a receipt containing the trigger hash, the final state (completed or failed), timing data, the committee seed, the definition hash, the namespace, and the hashes of all consensus blocks. This receipt enters the settlement pipeline described in Section 6.

## Committee Selection

Committee selection determines which validators participate in consensus for a given workflow execution. The selection must be deterministic (all honest nodes compute the same committee), unpredictable (no party can influence or predict committee composition before the trigger), and capability-aware (only validators with the required capabilities are eligible).

W3.io achieves this with a seeded Fisher-Yates shuffle.

The seed is derived from two values: the cumulative settlement root and the trigger hash. The cumulative root is the global sparse merkle tree root from the most recently settled epoch. It depends on every workflow receipt ever settled across all namespaces and all prior epochs. An attacker trying to predict or influence committee membership would need to control the settlement of all workflows across the entire network, not just the target workflow. The trigger hash adds per-run entropy that is unique to this specific workflow execution. Together they function like a verifiable random function output: deterministic, unpredictable before the epoch settles, and publicly verifiable by anyone who knows the on-chain root.

The seed feeds a ChaCha20 pseudorandom number generator [@nir2018chacha20], which drives the Fisher-Yates shuffle over the eligible validator set. ChaCha20 is a stream cipher used here as a cryptographically secure PRNG. It replaced an earlier linear congruential generator that was predictable and trivially invertible. The security of committee selection depends on the PRNG being non-invertible. ChaCha20 provides this.

Before shuffling, the validator set is filtered by capabilities. Each validator declares a capability bitmap at registration: whether it maintains an Ethereum WebSocket connection, an Avalanche WebSocket connection, GPU compute access, or other resources. A workflow that triggers on Ethereum events requires validators with the Ethereum WebSocket capability. The shuffle operates only on validators whose capabilities satisfy the workflow's requirements, ensuring that selected committee members can actually perform the work.

The minimum committee size in production is configurable through governance. Larger committees provide stronger Byzantine fault tolerance (more members must be compromised) but increase the P2P message overhead per step. The default minimum is 10, giving f=3 tolerance.

## Four Consensus Contexts

BOSCO is used in four distinct contexts within the protocol. The algorithm is identical in each case. What differs is the proposal value, the committee composition, and the committee lifetime.

**Step runner selection.** For each workflow step, the per-run committee agrees on which validator executes it. The proposal value is the selected runner's identity. This is the highest-stakes use of BOSCO because it directly determines who controls the step's execution. Committee size follows the governance-defined minimum (default 10 members, f=3). The committee is formed at trigger time and persists for the duration of the workflow run.

**Step attestation.** After execution, the same per-run committee agrees on the canonical assessment of the result. The proposal value is the attestation set (each member's confirmed/rejected/indeterminate verdict). This separates execution from evaluation: the runner produces the result, but the committee decides whether to accept it. A single compromised runner cannot force a bad result through consensus because the committee independently evaluates the output.

**Trigger confirmation.** Dedicated monitor groups run BOSCO to confirm external events before dispatching workflow execution. A monitor group is a small committee (7 members, f=2) assigned to a specific trigger type. Multiple workflows that watch the same event (for example, the same ERC-20 Transfer event on the same contract) share a single monitor group. This prevents trigger spoofing: a single validator claiming an event occurred is not sufficient to start a workflow. The monitor group must reach BFT agreement on the trigger evidence, including temporal validation that rejects future-dated events.

**Epoch manifest agreement.** The aggregation committee uses BOSCO to agree on which workflow receipts are included in each settlement epoch. The aggregation committee is larger (30 members, f=9) and longer-lived (persists for an entire epoch term, not just one workflow run). The proposal value is the receipt manifest: a sorted list of receipt hashes. Once the manifest is agreed upon, every honest member independently builds the same sparse merkle tree from the same receipts, producing the same cumulative root. This root is then signed and submitted to the L1 contract (Section 6).

In every context, the same properties hold: 2f+1 agreement is required, leader failure triggers automatic view change, and the decision is deterministic given the same inputs. W3.io does not need four consensus algorithms. It needs one good one, applied consistently.
