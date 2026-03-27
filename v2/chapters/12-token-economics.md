# Token Economics

Token economic parameters are being finalized in coordination with legal counsel and are subject to change before the Token Generation Event. This section describes the structural design. Specific values (total supply, allocation percentages, vesting schedules, emission rates) will be published when finalized.

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

## Dual-Token Revenue Model

W3.io separates its token economy into two currencies with distinct roles.

**W3 token** is the utility and governance token. Used for staking, collateral, access control, and network contribution rewards. In the early network when revenue is low, rewards are denominated in W3 tokens funded by the protocol treasury.

**USDC** is the payment currency. Workflow execution fees, partner revenue, and settlement costs are denominated and settled in USDC. As the network matures and generates real revenue, the reward mix shifts from W3 token emissions toward USDC revenue sharing.

All incentive types use the same hybrid formula:

```
reward = max(floor, percentage * revenue)
```

Early network: the floor dominates, treasury subsidizes in W3 tokens. Mature network: the percentage dominates, self-sustaining from USDC fees. The crossover happens automatically as revenue grows past the floor. No governance action needed.

The `rewardSplit` parameter (governance-controlled) governs the mix between W3 token and USDC rewards, adjustable as the network matures.

## Scarcity Mechanics

Circulating supply is structurally constrained by participation requirements.

As the network grows, more partners require more staked collateral. More subnets mean more tokens locked. More validators mean more tokens bonded. The collateral requirements scale with network size, compounding demand without reliance on speculative interest.

Forfeited stakes (from partners who exit or validators who are slashed) are redistributed to remaining participants, not released to the open market. This means tokens leave circulation permanently when participants exit, while remaining participants gain proportionally. The supply available for trading decreases as the network grows.

These mechanics are structural. They are consequences of the participation model, not artificial scarcity mechanisms bolted on after the fact.
