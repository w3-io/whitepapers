# Ecosystem

## The B2B2C Model

W3.io is not a developer tool that sells directly to end users. It is infrastructure that powers ecosystem partners, who in turn serve their own communities and customers. This B2B2C model (business to business to consumer) is how W3.io generates network effects without requiring W3.io itself to acquire end users.

Approximately 20 network partners will operate at launch. Each partner operates a **subnet**: a staked position in the network that grants access to W3.io's execution and settlement infrastructure. Partners use this access to build solutions for their own markets, whether that is payments, compliance, data analytics, AI, or decentralized finance.

Partners are not passive integrations. Each partner stakes W3 tokens to operate their subnet, is required to distribute a portion of their allocated tokens to their community participants, and is compensated for operating subnet infrastructure and delivering services to their community. This creates aligned incentives: partners succeed when they drive real usage through the network, not when they hold tokens passively.

The community participants within each partner's subnet take on active roles:

- **Sales teams** drive adoption by onboarding end users, compensated based on measurable adoption outcomes
- **Solution builders** develop full-scale applications on the network, compensated based on the usage their applications generate
- **Validators** (also referred to as guardian operators) maintain the integrity and security of the network, compensated for consensus participation, step execution, and trigger monitoring (see Section 9)

## Named Partners

W3.io's ecosystem includes partners across the full spectrum of Web3 infrastructure.

| Partner | Category | Capability |
|---------|----------|-----------|
| Space and Time | Data | ZK-proven SQL queries across EVM chains |
| Hyperbolic | AI/Compute | Decentralized AI inference |
| Pyth | Oracles | Real-time price feeds across 400+ assets |
| Chainalysis | Security | Sanctions screening and risk scoring |
| EigenLayer | Infrastructure | Restaking and shared security |
| Dentity | Identity | Decentralized identity verification |
| Kite AI | AI | AI model serving and training |
| Yelay | DeFi | Yield optimization infrastructure |
| Circle | Payments | USDC stablecoin issuance and APIs |
| Stripe | Payments | Fiat-to-crypto payment rails |

Each partner's capabilities are exposed as **actions** within the W3.io protocol: versioned, namespace-scoped, independently deployable components that any workflow can invoke. When a developer writes `uses: w3-io/w3-sxt-action@v1` in a workflow YAML, they are invoking Space and Time's query capability through W3.io's action registry.

## The Action Registry

Actions are the protocol's unit of capability. The action registry tracks every published action, its owning namespace, its version history, and its interface specification.

Actions are published as container images with a standard entry point. The W3.io runtime handles image pulling, environment setup, input injection, output parsing, and timeout enforcement (Section 4). Action authors only need to write the logic. The protocol handles the infrastructure.

The registry supports versioning. A workflow that references `w3-io/w3-sxt-action@v1` will always get the v1 interface, even after v2 is published. This prevents upstream action updates from breaking deployed workflows.

Receipts record which actions were used in each workflow execution through the `actions_used` field. This creates a complete audit trail of partner capability consumption, enabling per-partner attribution for revenue distribution and analytics.

## W3.cloud

W3.cloud is W3.io's decentralized compute and storage offering, providing AWS S3-compatible storage and container-based compute across a distributed infrastructure. W3.cloud serves as the infrastructure layer for workloads that are always-on (databases, API servers, streaming consumers) rather than event-triggered (workflows).

W3.cloud complements W3.io's workflow execution. Workflows handle event-driven, step-by-step computation with consensus on each step. W3.cloud handles persistent services that workflows interact with: databases that store workflow results, API servers that expose data to external consumers, and long-running processes that feed events into workflow triggers.
