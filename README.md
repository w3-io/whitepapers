# W3.io Protocol Whitepaper

**Verifiable Workflow Execution with On-Chain Settlement**

[Download the latest PDF](v2/output/w3-whitepaper.pdf)

## Overview

W3.io is a workflow execution protocol that connects fragmented Web3 infrastructure into verifiable, multi-step workflows. Developers compose workflows from modular actions using GitHub Actions-compatible YAML. A distributed validator network executes each step with BFT consensus and produces cryptographic settlement receipts anchored to an EVM L1.

## Contents

| Section | Topic |
|---------|-------|
| 1 | Introduction: the integration gap and W3.io's approach |
| 2 | Architecture: ingredients, recipes, solutions, spine and ribs |
| 3 | Workflows: GHA syntax, triggers, step kinds, expressions |
| 4 | Execution: Backend trait, Docker isolation, timeouts |
| 5 | Consensus: BFT protocol, 4-state machine, committee selection |
| 6 | Settlement: receipts, epochs, two-level SMT, L1 anchoring |
| 7 | Cryptography: BLS12-381, keccak256, ChaCha20, JMT |
| 8 | Namespaces: hierarchical multi-tenancy, authority/payer |
| 9 | Validators: KYC, capabilities, heartbeat, decentralization |
| 10 | Ecosystem: B2B2C model, partners, action registry |
| 11-12 | Token: utility, economics, dual-token model |
| 13 | Governance: GIPs, veto, decentralization roadmap |
| 14 | Security: BFT assumptions, threat model, risk factors |
| 15 | Roadmap: current state, post-v1 development |

## Building

Requires [pandoc](https://pandoc.org/) and [tectonic](https://tectonic-typesetting.github.io/):

```bash
brew install pandoc tectonic
cd v2
./build.sh
# Output: v2/output/w3-whitepaper.pdf
```

## Source

The whitepaper is written in Markdown with pandoc citation support. Each section is a separate file in `v2/chapters/` for independent editing. Citations are in `v2/references.bib`.

## Links

- [W3.io](https://w3.io)
- [Protocol Source Code](https://github.com/w3-io/protocol)
- [Settlement Layer Specification](https://github.com/w3-io/protocol/tree/audie/settlement-spec-update/docs/settlement)
