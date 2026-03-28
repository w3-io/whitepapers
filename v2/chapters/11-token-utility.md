# Token Utility

## Four Participation Roles

The W3 token gates participation in the network. Every participant role requires staking tokens as collateral. This is not passive staking for yield. It is a commitment mechanism that aligns incentives with active contribution.

**Ecosystem partners** post collateral to operate a subnet. The subnet is the partner's position in the network: it grants access to W3.io's execution and settlement infrastructure, allows the partner to publish actions, and obligates the partner to distribute a portion of tokens to their community participants. Unstaking forfeits the remainder of the partner's allocation. This creates a strong disincentive to churn.

**Solution builders** post collateral to deploy applications on the network. Builders are compensated based on the usage and demand their applications generate. The collateral requirement ensures that deployed applications have a committed maintainer.

**Sales teams** post collateral to participate in adoption programs. Sales participants are compensated based on measurable outcomes: users onboarded, workflows deployed, transaction volume generated. The collateral aligns sales incentives with long-term network health rather than short-term user acquisition.

**Validators** bond tokens to participate in consensus. Validator collateral is subject to slashing for provable misbehavior (equivocation, invalid signatures) and tiered forfeiture for repeated force-exits due to liveness failures. Validator compensation is based on active participation: signing epochs, executing steps, monitoring triggers.

## Fee Structure

Revenue from workflow execution flows in stablecoins (USDC), not in the W3 token. This separation is fundamental to the economic design. Businesses need predictable costs. A workflow that costs $0.05 today should cost approximately $0.05 tomorrow, regardless of token price movements. Stablecoin-denominated fees provide this predictability.

The W3 token is used for staking and access control. It is not the medium of exchange for workflow fees.

## Staking Mechanics

Staked tokens are locked for the duration of the participant's active role. The lock is not time-based (stake for N months). It is role-based (stake while you are a partner, builder, sales participant, or validator).

If a participant decides to exit, the consequences depend on the role:

- **Partners**: unstaking forfeits the remainder of the initial allocation. Forfeited tokens are redistributed to active participants as part of the network's collateral maintenance process.
- **Validators**: voluntary exit follows the drain process (complete in-flight work, then fully exit). Collateral is returned minus any slashing penalties. Force-exit due to liveness failure triggers tiered forfeiture: first offense forgiven (hardware failures happen), escalating with repeated force-exits.
- **Builders and sales**: collateral returned on clean exit after any active commitments are fulfilled.

## What the Token Is Not

The W3 token does not represent equity, debt, or ownership rights in W3.io or any affiliated legal entity. It does not confer rights to protocol revenues, dividends, or other distributions. Holding the token does not entitle the holder to any payment or consideration beyond the protocol utilities described above.

The token's design is focused on network participation and security. Active participation roles require token collateral. Holding the token without performing an active role does not generate any compensation or other benefit.
