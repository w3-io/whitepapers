# Token Economics

Certain token economic parameters (total supply, allocation percentages, and emission rates) are being finalized in coordination with legal counsel and are subject to change before the Token Generation Event. The structural design and vesting schedules described below are committed. Specific allocation values will be published when finalized.

## Supply and Allocation

The total supply of W3 tokens will be fixed at genesis. There is no mechanism for minting additional tokens after the Token Generation Event.

The supply will be allocated across the following categories:

| Category | Purpose | Vesting |
|----------|---------|---------|
| Ecosystem and Community | Airdrops, grants, partnerships, liquidity provisioning | Partial unlock at TGE, remainder vesting over time |
| Team | Core team building and maintaining the protocol | 12-month cliff, 36-month linear vesting |
| Investors | Early and strategic investors providing capital | 12-month cliff, 36-month linear vesting |
| Foundation Treasury | Protocol development, ecosystem growth, operational reserves | Governed by Foundation |

Specific allocation percentages and token amounts are TBD and will be disclosed publicly before TGE. Vesting is enforced on-chain through audited smart contracts. No single party can accelerate or override vesting schedules unilaterally.

At TGE, insider tokens (team, investors, advisors) will be fully locked. The only unlocked tokens at launch come from the Ecosystem and Community allocation.

## Dual-Token Model

W3.io uses two currencies with distinct roles.

**W3 token** is the utility and governance token. Used for staking, collateral, access control, and compensation for active network roles. Participants who perform work for the network (executing steps, validating attestations, monitoring triggers, onboarding users) receive compensation denominated in W3 tokens during the early network phase.

**USDC** is the payment currency. Workflow execution fees are denominated and settled in USDC, providing cost predictability for businesses using the protocol. As the network matures, governance may adjust the compensation structure for active participants to include USDC alongside or instead of W3 token compensation, subject to governance proposals and applicable regulatory review.

Compensation rates for active roles are governance-controlled parameters. They reflect the cost of the services provided (compute, bandwidth, availability commitment) and are subject to adjustment as the network's operational profile evolves. Compensation is paid only to participants actively performing their role. Holding the token without performing an active role does not generate any compensation.

## Collateral Lifecycle

Active participation in the network requires staked collateral. Tokens are locked for the duration of the participant's role and returned on clean exit (minus any penalties for validators who are slashed for provable misbehavior).

When a partner exits the network and forfeits their remaining allocation, those tokens are redistributed to other active participants rather than returned to general circulation. This redistribution is a consequence of the partner agreement structure described in Section 11, not a separate mechanism. Its purpose is to maintain the collateral base of the network as participants change over time.

The total supply is fixed at genesis. No minting occurs after the Token Generation Event. The Foundation Treasury allocation funds ecosystem development and is governed by the Foundation with transparency obligations described in Section 13.
