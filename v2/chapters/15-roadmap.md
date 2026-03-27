# Roadmap

## Current State

W3.io's protocol is implemented in Rust, open-source, and deployed on testnet. The testnet processes over 200,000 workflow executions per day across a multi-node validator network. The protocol includes:

- Workflow execution runtime with GHA-compatible YAML compiler
- BFT consensus engine with 4-state machine for per-step agreement
- P2P networking via libp2p with gossipsub and direct committee messaging
- SSZ wire format for all protocol messages
- Native blockchain actions for Ethereum, Solana, and Bitcoin
- Ecosystem partner actions (Space and Time, Chainalysis, Pyth, Circle, Stripe, Hyperbolic, Redis, email)
- Backend trait with Docker execution, timeout enforcement, and signal escalation
- BLS12-381 signing with domain separation and PopVerifiedKey type-state enforcement
- Sparse merkle tree library with two-level cumulative structure
- Write-ahead log for epoch accumulation with crash recovery
- WAL-to-SMT epoch pipeline for settlement processing
- Validator capability bitmaps with ChaCha20 committee selection
- Validator join/leave lifecycle with heartbeat liveness detection
- Trigger definition registry with deduplication and monitor group assignment
- Namespace model with hierarchical authority and payer inheritance
- L1 settlement contracts (EpochSettlement, ValidatorSet, WorkflowRegistry, SMTVerifier)
- BLS quorum-signed epoch submission pipeline
- End-to-end integration test suite

Creatorland, W3.io's anchor client, is deployed on testnet as a live enterprise workflow.

## Post-v1 Development

The following extension points are designed into v1 interfaces and will be developed after the settlement layer is in production.

**VRF committee election.** Replace the deterministic ChaCha20-based committee selection with verifiable random function output. VRF provides cryptographic proof that the committee was selected correctly, removing the need to trust the seed derivation. Entry point: `ValidatorView::get_participants()`.

**Decentralized governance.** Transition from Foundation-managed governance (Phase 1) through dual authorization (Phase 2) to fully on-chain staking governance (Phase 3). Remove privileged administrative roles. Entry point: governance contract deployment and role admin transfer.

**Data availability layer.** Integrate Storj or Celestia for long-term proof archival. Currently validators store all execution traces. A dedicated DA layer provides durability guarantees independent of validator set churn. Entry point: W3Uri resolver with remote storage backends.

**Namespace auth v2.** Per-workflow authorization policies and key-based auth beyond address-based control. Supports use cases where different workflows within the same namespace have different access rules. Entry point: `WorkflowRegistry.sol` auth functions.

**Validator capability proofs.** Replace self-declared capability bitmaps with proven capabilities. A validator proves it has an Ethereum WebSocket connection by signing a recent block hash. Entry point: `ValidatorView` capability filter with proof verification.

**Zero-downtime protocol upgrades.** Epoch-activated feature flags that allow breaking changes (wire format, consensus parameters) to deploy without network downtime. Validators upgrade on their own schedule within a window. All nodes switch behavior at the same epoch boundary. Entry point: governance-set activation epoch with dual code paths.

**Censorship dispute and slashing.** On-chain dispute mechanism where namespace owners can prove receipt censorship using signed namespace summaries. Slashing via signer bitmap attribution. Entry point: dispute contract consuming `GossipReceipt` and `NamespaceSummary` evidence.

**Field-level execution proofs and the `w3:` syscall.** Complete the proof path from on-chain epoch root to individual execution field values. The `w3:` step kind enables workflows to generate merkle proofs about their own consensus-attested execution data and submit those proofs to L1 contracts. This enables selective disclosure (prove which validator ran a step without revealing other fields) and on-chain composability (a DeFi contract gates an action on a specific field of a compliance workflow's result). Foundation: `w3io-proof` crate (PR #1507). Entry point: `w3:` runtime handler wired to real `ConsensusStepRun` data.

**Firecracker execution backend.** MicroVM isolation for stronger step execution guarantees. Each step executes in its own lightweight VM with a dedicated kernel. Entry point: Backend trait implementation alongside Docker.
