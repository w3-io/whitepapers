# Namespaces

## Meeting People Where They Are

Most blockchain protocols force a flat ownership model. One address owns one account. One account deploys one contract. Organizational structure, if it exists at all, is layered on top through multi-sig wallets or custom access control contracts. This works for individual developers. It does not work for companies, teams, partnerships, or any organization more complex than one person with one wallet.

Real organizations are hierarchical. A company has departments. Departments have teams. Teams have members. Some resources are shared. Some are isolated. Billing might be centralized or delegated. Authority might cascade from the top or be granted locally. The organizational structure changes over time: departments merge, teams spin out, companies get acquired.

W3.io's namespace model is designed to meet these organizations where they are. A solo developer creates a namespace and deploys workflows. A company creates a namespace with sub-namespaces for each department. A venture studio creates namespaces for each portfolio company under a parent namespace. An open-source project creates a namespace with no authority and no payer, and anyone can deploy to it, paying for their own runs.

The same primitive handles all of these cases. No rigid tiers, no enterprise-only features, no upgrade path from "personal" to "organization." Just a tree that grows with you.

## Namespace Identity

Every namespace is identified by a permanent 32-byte value derived from its creator's address and a per-creator nonce:

```
namespace_id = keccak256(creator_address, nonce)
```

The creator is immutable, like a contract deployer. It is recorded on-chain but is not the ongoing authority. This is a critical distinction. The identity of a namespace never changes, regardless of who controls it, who pays for it, or where it sits in the hierarchy. Receipts, SMT keys, and on-chain references all use the namespace ID. If the ID changed when authority transferred, every historical reference would break.

The nonce allows a single creator address to produce multiple namespaces. The default nonce (all zeros) works for creators who only need one. A creator who needs many (staging, production, per-client) increments the nonce.

## Three Roles

Each namespace has three identity fields that serve different purposes.

**Creator** is the address that created the namespace. Immutable. Recorded on-chain for provenance. Not an ongoing role. The creator has no special powers after creation, just as a contract deployer has no special powers over a deployed contract (unless the contract grants them).

**Authority** is the address that controls the namespace. The authority can deploy and undeploy workflows, set access policies, manage child namespaces, and initiate transfers. Authority is transferable through a two-step process with a cancellation window, protecting against instant namespace theft via a compromised key.

**Payer** is the address that pays for workflow executions in the namespace. Payer is transferable independently of authority. This separation is fundamental. The person who controls what workflows run is not necessarily the person who pays for them. A company's CTO controls the deployment pipeline. The company's treasury pays for the compute.

All three roles can be set at creation time or left empty to inherit from the parent.

## Hierarchy and Inheritance

Namespaces form a tree rooted at a `w3` root namespace. Any namespace can be a parent. The tree can be arbitrarily deep.

```
w3 (root: authority=none, payer=none)
  acme (authority=0xCEO, payer=0xTreasury)
    engineering (authority=inherited, payer=0xEngBudget)
    finance (authority=0xCFO, payer=inherited)
  opensource-project (authority=none, payer=none)
```

Authority and payer inherit down the tree by default. If a namespace has no explicit authority, the protocol walks up the tree until it finds one. If a namespace has no explicit payer, the same walk happens. The root namespace has no authority and no payer. Inheriting all the way to root means "open": anyone can act as authority (public namespace), and each caller pays for their own workflow runs.

This inheritance model makes common patterns simple.

A **company** sets authority and payer on its top-level namespace. Every child namespace inherits both unless explicitly overridden. The engineering team gets its own budget (overrides payer) but inherits the CEO's authority for deployment control.

An **open-source project** sits under root with no authority and no payer. Anyone can deploy workflows. Anyone can trigger them. Each user pays for the runs they initiate. No gatekeeper.

A **multi-entity partnership** creates a shared parent namespace with joint authority (a multi-sig), and each partner company has a child namespace with its own authority and payer. Shared infrastructure lives in the parent. Partner-specific workflows live in the children.

A parent's authority can intervene in children: freeze operations, propose authority changes. But local authority takes precedence for day-to-day operations. The parent's ability to intervene is an administrative backstop, not day-to-day control.

## Reparenting

Namespaces can move. A child can transfer from one parent to another, or move to root to become a top-level namespace. This models real organizational changes: spinouts, acquisitions, reorganizations.

Reparenting requires consent from both sides. The child's authority agrees to leave the current parent. The new parent's authority agrees to accept the child. The old parent does not get a veto. The child is sovereign enough to leave.

This models:

- **Spinout**: a department becomes its own company. The child namespace moves to root. Root is open, so no consent is needed from root.
- **Acquisition**: company B acquires a division of company A. The child namespace moves from A's tree to B's tree. Both B's authority and the child's authority must consent.
- **Reorganization**: a team moves from one department to another within the same company. The child namespace moves between sibling namespaces.

Reparenting uses the same two-step process with cancellation window as authority transfer. The namespace ID does not change when reparented. All historical receipts, SMT entries, and on-chain references remain valid.

## Namespace-Scoped Actions

Actions (the protocol-level representation of ecosystem partner capabilities) are scoped to namespaces. Each action's identity is derived from its owning namespace and action name:

```
action_id = keccak256(namespace_id || action_name)
```

This means the same action name in two different namespaces produces two different action IDs. A partner's `compliance-check` action in the `chainalysis` namespace is a different protocol object from a `compliance-check` action in a different namespace. There is no global action name collision.

Workflow receipts include the `actions_used` field: a sorted list of action IDs for every action invoked during the run. This creates a per-execution record of which partner capabilities were consumed, enabling per-partner attribution for billing, analytics, and revenue distribution.

W3.io reserves a protocol namespace for built-in actions (HTTP, blockchain primitives, core utilities). Only protocol governance can register actions in this namespace. Partner namespaces are self-governed by their authority.

## Path to Chain-Native Namespaces

W3.io operates as an Avalanche L1, which means the chain binary is under the protocol's control. This opens an architectural path that pure EVM protocols do not have: implementing namespaces as a chain-native precompile rather than a Solidity contract.

A precompile executes at native speed, not EVM bytecode interpretation speed. Namespace operations like resolving the authority or payer for a given namespace ID require walking up the inheritance tree, potentially multiple storage reads at each level. As a Solidity contract, this is functional but expensive. As a precompile, it becomes a single native call that returns in microseconds.

More importantly, a precompile makes namespaces a first-class primitive of the chain itself. Other contracts on the L1 resolve namespace authority as cheaply as they call `ecrecover`. The settlement contracts, the workflow registry, and any future protocol contracts can authorize operations through the namespace precompile without the overhead of cross-contract calls.

Namespaces are initially deployed as a Solidity contract with a UUPS upgrade path. Once the interface is finalized and battle-tested in production, the namespace logic migrates to a precompile. The Solidity contract becomes a thin wrapper that delegates to the precompile, maintaining backward compatibility for any contracts that reference the original address. This staged approach avoids baking an unproven interface into the chain binary while keeping the long-term architecture clean.

If the namespace model proves its utility in production, the interface is a candidate for standardization as an EIP or AIP, enabling other EVM protocols to adopt hierarchical namespace resolution as a shared primitive.
