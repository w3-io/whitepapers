# Risk Factors

Participation in the W3.io network and holding the W3 token involve significant risks. The following is not exhaustive. Prospective participants should carefully consider these factors.

## Technology Risk

W3.io's protocol is complex software. Despite testing and code review, smart contracts and protocol logic may contain undiscovered bugs that could result in loss of staked funds, incorrect workflow execution, or settlement failures. Third-party security audits are planned but have not yet been completed. The protocol depends on underlying infrastructure (Avalanche L1, libp2p, Docker) that may itself contain vulnerabilities.

## Regulatory Risk

The regulatory environment for digital assets is evolving. The W3 token may be classified differently by different jurisdictions. Regulatory changes could restrict the token's availability, limit its utility, or impose compliance requirements that affect the protocol's operation. W3.io does not provide legal, tax, or investment advice. Participants should consult their own advisors.

## Centralization Risk

At launch, the W3.io Foundation holds administrative keys that can add or remove validators, pause contracts, veto governance proposals, and initiate contract upgrades. While these powers are disclosed, time-locked (for non-emergency actions), and subject to a published decentralization roadmap, they represent centralized control over the protocol. The decentralization roadmap does not have a binding timeline. Participants should evaluate the protocol's current governance posture, not only its intended future state.

## Validator Set Risk

W3.io launches with a permissioned, KYC-verified validator set. The initial validator set is small relative to established blockchain networks. A smaller validator set is more susceptible to coordinated failure, collusion, or external pressure than a larger, permissionless set. The BFT security guarantees assume fewer than one-third of committee members are Byzantine. This assumption is stronger for larger committees and weaker for smaller ones.

## Smart Contract Risk

The L1 settlement contracts (EpochSettlement, ValidatorSet, WorkflowRegistry, SMTVerifier) are upgradeable via UUPS proxy with timelock governance. While upgradeability allows bug fixes, it also means the contract behavior can change after deployment. Participants should be aware that the contracts they interact with today may behave differently in the future, subject to governance approval and timelock delays.

## Market Risk

The W3 token may lose value. The token's utility is tied to the W3.io protocol's adoption and usage. If the protocol does not achieve sufficient adoption, the demand for the token may be insufficient to support its value. The token is not redeemable for any asset and has no price floor.

## External Dependency Risk

W3.io workflows depend on external services provided by ecosystem partners (data providers, payment processors, oracle networks). The availability, accuracy, and continued operation of these services is outside W3.io's control. A partner service outage or discontinuation could affect workflows that depend on that partner's actions.

## Execution Attestation, Not Computational Proof

W3.io provides consensus-attested execution. A BFT quorum of validators agrees on the result of each workflow step. This is distinct from computational integrity proofs (such as ZK proofs) where a mathematical proof guarantees the computation was performed correctly. For workflow steps that interact with external, non-deterministic services, committee members may be unable to independently verify the result and may attest based on the runner's reported output. Participants should understand this distinction when evaluating the protocol's security guarantees.

## Key Person Risk

The protocol's continued development depends on the core team and key contributors. The departure of key personnel could affect development velocity, technical direction, or operational continuity.
