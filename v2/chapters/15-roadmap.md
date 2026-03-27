# Roadmap

## Current State

W3.io's protocol is implemented in Rust, open-source, and deployed on testnet. The testnet processes over 200,000 workflow executions per day with a multi-node validator cluster. The following components are built and operational:

- Workflow execution runtime with GHA-compatible YAML parser
- BOSCO BFT consensus engine (2,720 lines, 4-state machine)
- P2P networking via libp2p with gossipsub and direct messaging
- Native blockchain actions for Ethereum, Solana, and Bitcoin
- Ecosystem partner actions (Space and Time, Chainalysis, Pyth, Circle, Stripe, Hyperbolic, Redis, email)
- Backend trait with Docker execution, timeout enforcement, and signal escalation
- SSZ wire format for all P2P messages
- BLS12-381 signing with PopVerifiedKey type-state enforcement
- Sparse merkle tree library (JMT + keccak256)
- Write-ahead log for epoch accumulation
- WAL-to-SMT epoch pipeline
- Validator capability bitmaps with ChaCha20 committee selection
- Validator join/leave lifecycle with heartbeat liveness detection
- Trigger definition registry with deduplication and monitor seed derivation
- CLI for workflow deployment, triggering, and monitoring

## What's Next

The remaining work is organized into merge points: short PR stacks (2-5 PRs each) that merge to master at defined points. Each merge point is a deployable, testable state.

**BOSCO message infrastructure.** Typed BOSCO message payloads (proposal, vote, decision, view change) and direct P2P transport for committee messaging. This is the gate for the consensus upgrades below.

**BOSCO consensus integration.** Replace the current step runner selection and step attestation mechanisms with BOSCO consensus. This is the highest-value, highest-risk change: it moves the protocol from unanimous consensus (one offline validator blocks everything) to BFT (up to f offline validators tolerated).

**Trigger rewiring.** Monitor groups with BOSCO confirmation for trigger events. Rotation handoff between monitor group terms. Modified workflow initialization to receive confirmed triggers rather than running trigger consensus inline.

**Settlement wiring.** Manifest BOSCO for epoch close. BLS signing pipeline for quorum signatures. Proof tiers (settlement proof and execution proof). EVM submitter for L1 anchoring.

**L1 contracts.** EpochSettlement, ValidatorSet, WorkflowRegistry, SMTVerifier, and RewardPool Solidity contracts. Timelock and access control governance plumbing.

**Integration and UX.** End-to-end test suite (13 scenarios from trigger to L1 settlement). Explorer integration. CLI settlement commands and operational runbooks.

## Post-v1

Nine extension points are designed into v1 interfaces but deferred to after the settlement layer ships. Each has a specific code location where future work begins:

- VRF committee election (replacing deterministic ChaCha20 with verifiable randomness)
- Decentralized governance (on-chain parameter control, removing Foundation admin roles)
- DA layer integration (Storj, Celestia for long-term proof archival)
- Namespace auth v2 (per-workflow policies, key-based auth beyond address-based)
- Validator capability proofs (proven, not self-declared)
- Censorship dispute and slashing enforcement
- Zero-downtime breaking protocol upgrades (epoch-activated feature flags)

These are not speculative features. They are interfaces and extension points designed into the v1 codebase with specific entry points documented in the implementation plan.
