# Governance

## Protocol Evolution

W3.io employs an on-chain governance system in which token holders may submit and vote on Governance Improvement Proposals (GIPs). Governance covers protocol parameters, fee structures, staking compensation rates, treasury allocations, new module integrations, and validator set policies.

## Proposal Process

Any token holder meeting the minimum proposal threshold may submit a GIP. Proposals follow a defined lifecycle:

1. **Discussion**: the proposer publishes the GIP to public forums for community feedback
2. **Submission**: the proposal is submitted on-chain with a deposit
3. **Voting period**: token holders vote for or against. Proposals require a supermajority (66% of participating token holders) to pass
4. **Execution**: approved proposals paired with audited code execute automatically through the timelock. Proposals without code are implemented by the core team in alignment with the approved specification

## Governance Scope

GIPs can address:

- Protocol parameter changes (epoch duration, committee sizes, timeout values)
- Fee structure adjustments
- Staking reward rates and emission schedules
- Treasury allocations for ecosystem development
- New module integrations and action registry policies
- Validator onboarding standards and KYC provider selection
- Emergency actions (contract pause) under narrowly scoped conditions

## Veto and Transition

The core team holds a limited veto during the early phase, restricted to security and regulatory concerns. This authority is temporary and disclosed. Every exercise of the veto is public and must include a written justification.

The veto is a safety mechanism for a young protocol. Novel governance attacks, regulatory surprises, or critical security vulnerabilities may require faster response than a governance vote allows. The veto exists for these cases, not for routine decisions.

The veto authority phases out as governance matures, following the same three-phase decentralization path described in the Validators section (Section 9): Foundation-managed, dual authorization, then fully on-chain governance. The goal is a protocol that does not need privileged roles. The veto is the bridge between here and there.
