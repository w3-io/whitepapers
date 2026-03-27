# Settlement

## Why Settlement Matters

W3.io workflows execute off-chain. Validators run containers, reach consensus on results, and produce outputs. But without settlement, verifiability ends at the validator set. A third party who was not part of the consensus has no way to independently confirm that a workflow ran, what it produced, or when it executed.

Settlement bridges this gap. It takes the outputs of off-chain consensus and anchors them to a public blockchain, creating a permanent, independently verifiable record. After settlement, anyone with access to the L1 can verify a workflow execution. No access to the validator network required. No trust in any specific validator.

This is the difference between "the validators say it happened" and "the chain proves it happened."

## Receipts

When a workflow run completes, the consensus engine produces a **receipt**. The receipt is a compact summary of everything that matters about the execution. It contains 15 fields:

- **version**: receipt format version (currently 1)
- **namespace**: the namespace that owns the workflow
- **workflow_name_hash**: keccak256 hash of the workflow name
- **trigger_hash**: unique identifier for this specific run
- **definition_hash**: hash of the compiled workflow definition, matching the on-chain registry
- **l1_anchor_hash**: the L1 block hash at the time the workflow was triggered
- **final_block_hash**: hash of the last consensus block in the run's hashchain
- **end_state**: completed or failed
- **failure_reason**: if failed, why (runner timeout, attestation rejection, step error)
- **failure_data_hash**: hash of the failure details for diagnostic retrieval
- **actions_used**: sorted list of namespace-scoped action ID hashes used in the run
- **step_count**: total number of steps executed
- **start_time**: when the workflow started (UTC milliseconds)
- **end_time**: when it completed
- **committee_seed**: the seed used for committee selection, enabling anyone to reconstruct which validators participated

The receipt is ABI-encoded using the same layout as Solidity's `abi.encode`, producing a byte-for-byte match between the Rust and Solidity implementations. The receipt hash is `keccak256(abi.encode(receipt))`. This hash is what gets inserted into the sparse merkle tree and ultimately anchored on-chain.

The ABI encoding compatibility is verified by a golden test: the Rust implementation's output is compared against the output of `cast abi-encode` (the Solidity reference encoder) for identical inputs. If the encoding ever drifts, the test fails before the code ships.

## Epochs

Receipts are not settled individually. They are batched into **epochs**. An epoch is a fixed-duration window during which receipts accumulate. When the epoch closes, the aggregation committee agrees on the receipt manifest (the list of receipt hashes to include), builds the merkle tree, and submits the commitment to the L1.

Epoch mechanics:

- Epochs are numbered sequentially. Empty epochs (no workflows ran) are skipped. The contract accepts the next non-empty epoch regardless of how many empty epochs elapsed.
- Each epoch references the previous epoch's cumulative root, creating a hashchain of epochs on the L1. This prevents replay, reordering, and forking.
- A receipt that arrives after the epoch closes goes into the next epoch. The cutoff is hard. There is no grace period. Late receipts are not lost, they are deferred.
- The receipt manifest is agreed upon by the aggregation committee using BOSCO consensus (Section 5). This ensures all honest validators build the tree from the same receipt set.

Batching into epochs serves two purposes. First, it amortizes the gas cost of L1 submission across many workflow executions. At 100 workflows per epoch, the per-workflow settlement cost approaches zero. Second, it produces a cumulative root that covers the full history of all settled workflows, not just the current epoch. This is what makes historical verification possible without scanning the entire chain.

## The Two-Level Sparse Merkle Tree

W3.io uses a two-level cumulative sparse merkle tree [@jellyfish2021] to organize settled receipts.

**Level 1: Global tree.** The leaves are namespace roots, keyed by `keccak256("ns" || namespace_id)`. Each leaf's value is the root of that namespace's own tree. The global tree is sparse: only namespaces with at least one settled receipt have leaves. A namespace created on-chain but never used does not appear in the tree.

**Level 2: Per-namespace trees.** Each namespace has its own tree. The leaves are receipt hashes, keyed by `keccak256(version || namespace_id || trigger_hash || workflow_name_hash)`. Each leaf's value is the receipt hash.

Both trees use keccak256 hashing for EVM compatibility. The tree implementation wraps the Jellyfish Merkle Tree library (originally developed for the Diem/Aptos blockchain), which provides efficient path compression, incremental updates, and both inclusion and non-inclusion proofs.

The cumulative root after processing epoch N is the on-chain root for epoch N. It reflects the entire history of all receipts across all namespaces, not just epoch N's receipts. Like Ethereum's state trie, each epoch's root is a snapshot of the full world state at that point.

This structure enables three types of verification:

**Inclusion proof.** Prove that a specific workflow ran and settled. The verifier needs the receipt, a per-namespace merkle proof (receipt exists in the namespace tree), and a global merkle proof (namespace root exists in the global tree). Two proofs, checked against the on-chain root. Typical proof size is 2-3 KB.

**Non-inclusion proof.** Prove that a workflow did NOT run. The sparse merkle tree supports non-membership proofs: given a key, prove that no leaf exists at that position. This is critical for dispute resolution and billing ("you claim we didn't run your workflow; here's cryptographic proof that we did" or "you claim you ran it; prove it against the root").

**Composability.** Other smart contracts can verify workflow results on-chain. The `SMTVerifier` contract exposes a `verifyWorkflowResult()` function that accepts a receipt, two proofs, and an epoch number, and returns whether the receipt is valid against the on-chain root. A DeFi protocol can gate actions on workflow completion: "release payment only if this compliance workflow settled successfully."

## L1 Anchoring

The final step in settlement is submitting the epoch commitment to the L1 contract. This is a two-phase process.

**Phase 1: Manifest agreement.** The aggregation committee leader proposes the receipt manifest for the epoch. Committee members run BOSCO to reach consensus on which receipts are included. Once agreed, every honest member independently builds the same sparse merkle tree from the same receipts (deterministic: same receipts in the same order produce the same root).

**Phase 2: Root signing.** After building the tree, committee members produce a quorum signature over the epoch tuple: chain ID, contract address, epoch number, validator set version, cumulative root, previous root, receipt count, and namespace count. The chain ID and contract address serve as a domain separator, preventing signatures from one deployment being replayed on another. The quorum signature is an aggregate BLS12-381 signature [@irtf2022bls] verified on-chain via EIP-2537 precompiles [@eip2537].

The `EpochSettlement` contract verifies:

- The epoch number is greater than the last submitted epoch (monotonically increasing)
- The previous root matches the stored root from the last epoch (chaining, no forks)
- The quorum signature is valid against the known validator set
- The validator set version matches the current on-chain version

If all checks pass, the contract stores the new cumulative root, emits an `EpochSubmitted` event, and the epoch is settled. The cumulative root is now publicly queryable by any contract or off-chain verifier.

**Submission incentives.** The manifest BOSCO leader has priority to submit during a configurable window (default 30 seconds). After the window expires, any validator can submit, incentivized by a gas reimbursement bounty. This ensures that a single faulty leader cannot block settlement. The contract's idempotent design means racing submitters are harmless: the first valid submission is accepted, duplicates revert cheaply.

## Crash Recovery

Settlement is designed to survive node failures without losing data.

W3.io uses a write-ahead log (WAL) to track receipts and epoch state. Every receipt written to the WAL is durable (when backed by MDBX persistent storage). Every epoch status transition (open, closed, submitted, settled, failed) is recorded. If a node crashes mid-epoch, it restarts, opens the WAL (which self-heals to the last committed transaction), checks the L1 for the latest settled epoch, and resumes from where it left off.

The recovery sequence:

1. Open the WAL. MDBX guarantees consistency after unclean shutdown.
2. Read the latest settled epoch from the L1 contract. This is the source of truth.
3. Check the WAL for unsettled epochs. Any epoch in Closed or Submitted status needs re-processing or re-submission.
4. Backfill missing receipts from peers for the last 2 epochs.
5. Re-process if needed. Same receipts plus same manifest produces the same root. Deterministic replay is safe.
6. Check for in-flight L1 submissions. If an epoch was submitted but the WAL doesn't know, scan for it on-chain. The contract rejects duplicates.

The worst case after a power failure is a brief delay while the node catches up. No data is lost. No re-sync from genesis is required.
