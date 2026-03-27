# Key Contributions

W3.io makes five specific contributions to the state of decentralized infrastructure.

**1. GitHub Actions as the workflow language.** W3.io's workflow syntax is not a custom DSL. It is the same YAML grammar used by GitHub Actions, parsed by the same rules, supporting the same expression language. The developer population that already writes CI/CD workflows can write W3.io workflows with zero additional learning. No other decentralized execution protocol offers this on-ramp.

**2. One consensus algorithm, four contexts.** Rather than bolting different consensus mechanisms onto different protocol functions, W3.io uses a single BFT protocol for step runner selection, step attestation, trigger confirmation, and epoch manifest agreement. The algorithm is identical in each context. The proposal values and committee compositions differ. This uniformity simplifies security analysis: one protocol to audit, one set of properties to verify.

**3. Per-execution partner attribution.** Every workflow receipt includes an `actions_used` field: a sorted list of action IDs for every partner capability invoked during the run. This makes fee attribution, billing, and revenue allocation automatic by construction. There is no separate analytics pipeline or manual accounting. The settlement layer knows which partners contributed to every workflow execution.

**4. Non-inclusion proofs.** W3.io's sparse merkle tree supports proving that a workflow did NOT run. Most settlement layers can only prove what happened. W3.io can also prove what didn't. This is critical for dispute resolution ("you claim you ran my workflow; prove it against the on-chain root") and compliance ("prove that no unauthorized workflow executed in this namespace during this period").

**5. Stablecoin fees with token collateral.** Workflow execution fees are denominated in USDC. The W3 token is used for staking and access control, not as a payment medium. This avoids the circular dependency where using the token for fees creates artificial demand that inflates costs for users. Businesses get predictable pricing. Token utility comes from participation requirements, not forced usage.
