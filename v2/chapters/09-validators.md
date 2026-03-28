# Validators

## Becoming a Validator

W3.io's validator set is permissioned. Every validator operator is KYC-verified before joining the network. This is consistent with the protocol's focus on enterprise financial workflows, where the identity and accountability of consensus participants matters.

To join the network, an operator:

1. Completes KYC/KYB verification through the Foundation's approved provider
2. Posts W3 token collateral to the `ValidatorSet` smart contract
3. Submits a BLS12-381 proof of possession (signs their own public key with the `W3IO-BLS-POP-V1` DST)
4. Declares a capability bitmap describing what the validator can do
5. Enters the join queue

The on-chain contract verifies the proof of possession before accepting the key. This prevents rogue public key attacks on aggregate signatures. Once verified, the validator enters a sync period where it downloads recent state from peers. After sync completes, the validator becomes active and is eligible for committee selection at the next epoch boundary.

Epoch-boundary activation ensures that all validators agree on the validator set composition at any given time. A validator that registers mid-epoch does not participate in consensus until the next epoch starts. This prevents disagreements about committee membership during active consensus rounds.

## Capability Bitmaps

Not all validators are equal. Some maintain Ethereum WebSocket connections for chain event monitoring. Some have Avalanche WebSocket connections. Some have GPU compute resources. The protocol needs to select committees that can actually perform the required work.

Each validator declares a capability bitmap at registration: a 64-bit value where each bit position represents a specific capability.

| Bit | Capability | Meaning |
|-----|-----------|---------|
| 0 | `CORE_PROTOCOL` | Can run basic workflow steps |
| 1 | `ETHEREUM_WS` | Maintains Ethereum WebSocket connection |
| 2 | `AVALANCHE_WS` | Maintains Avalanche WebSocket connection |
| 3-63 | Reserved | Future protocol-defined capabilities |

When the committee selection algorithm runs for a workflow that monitors Ethereum events, it filters the validator set to only those with the `ETHEREUM_WS` bit set before shuffling. A validator without the required capability is never selected for work it cannot perform.

Capabilities are self-declared in v1. The validator claims what it can do, and the protocol trusts the claim. A future upgrade (tracked as a post-v1 fork point) adds capability proofs: a validator proves it has an Ethereum WebSocket by signing a recent Ethereum block hash, demonstrating live access to the chain.

## Join and Leave Lifecycle

Validators have a lifecycle managed by the protocol's lifecycle manager.

**Joining.** A new validator moves through: registration (on-chain), sync (download state from peers), activation (eligible for selection). The sync period prevents a new validator from being selected before it has the context needed to participate in consensus.

**Leaving voluntarily.** A validator signals intent to leave. It is immediately removed from future committee selections. However, it may still be part of in-flight workflow runs. The protocol drains active work: the validator completes any runs it is currently participating in, then fully exits. This prevents a departing validator from breaking consensus mid-workflow.

**Force-exit.** If a validator becomes unresponsive, the heartbeat mechanism detects it and initiates a force-exit. The validator enters the leave queue as if it had signaled voluntarily, but with a forfeiture penalty on its staked collateral (see Token Utility).

**Rejoining.** A validator that left can rejoin by going through the registration and sync process again. The force-exit counter is permanent per validator identity (Ed25519 key). A validator that force-exits repeatedly faces escalating penalties.

## Heartbeat and Liveness

Validators publish a heartbeat message every 30 seconds on the `validator-heartbeat` gossipsub topic. Each heartbeat contains the validator's public key, a timestamp, and the latest epoch number the validator has processed.

Other validators track incoming heartbeats. If a validator misses 3 consecutive heartbeats (90 seconds of silence), the tracking validator initiates a force-exit through the lifecycle manager.

The heartbeat mechanism includes a grace period for new validators. When a validator is first discovered (either because it just joined or because the tracking node just started), it receives a synthetic heartbeat at the current time. This gives the new validator a full 90-second window to send its first real heartbeat before any force-exit logic triggers. Without this grace period, a coordinated upgrade (where all validators restart simultaneously) would cause every validator to immediately force-exit every other validator.

The heartbeat is the protocol's liveness detector. It does not assess whether a validator is performing well, only whether it is alive. Performance assessment happens through the consensus mechanism itself: a validator that consistently fails to execute steps or produce valid attestations will be re-selected around, reducing its effective participation without requiring an explicit penalty beyond the consensus level.

## Progressive Decentralization

W3.io is designed to progressively decentralize control over the validator set. At launch, the Foundation operates the KYC allowlist and holds administrative keys through a team multi-sig with timelock controls. Over time, the protocol transitions toward a model where validator set participation is determined by on-chain staking mechanics: meet the minimum stake, pass KYC, submit proof of possession, join the set. The contract architecture supports this transition through transferable role administration.
