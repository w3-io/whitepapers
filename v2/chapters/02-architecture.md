# Architecture

## Ingredients, Recipes, and Solutions

W3.io's ecosystem is organized around three tiers of composability.

**Ingredients** are capabilities provided by individual ecosystem partners. Each partner exposes their capabilities as modular, reusable components within the W3.io ecosystem. Space and Time provides data queries. Circle and Stripe handle payments. Hyperbolic offers AI inference. Chainalysis handles compliance screening. Pyth delivers price feeds. An ingredient is a self-contained unit of functionality that can be invoked as part of a larger process.

**Recipes** combine two or more ingredients into adaptive logic that addresses a specific business need. A recipe defines the trigger conditions, the sequence of operations, the data flow between steps, and the failure handling behavior. Recipes are W3.io's unit of deployment. A developer writes a recipe, deploys it to the validator network, and it executes automatically when triggered.

**Solutions** are recipes integrated into end-user applications. A payments product, a compliance pipeline, a yield vault: each is a solution that composes ingredients through recipes to deliver a complete user experience. Solutions inherit the verifiability of the underlying protocol. Every step of every recipe execution is attested by consensus and provable against an on-chain commitment.

This model enables a network effect. Each new ingredient makes every existing recipe potentially more capable, and each new recipe demonstrates a pattern that other builders can adapt.

## Actions and Workflows

At the protocol level, ingredients become **actions** and recipes become **workflows**.

An action has a namespace-scoped identifier, a version, and defined inputs and outputs. W3.io ships with native actions for three blockchain families:

- **Ethereum**: balance queries, token transfers and approvals, contract deployment and calls, event monitoring, NFT operations, ENS name resolution
- **Solana**: balance queries, token accounts, program invocation, transfers, transaction monitoring
- **Bitcoin**: balance queries, UTXO management, fee estimation, transaction construction and broadcast

Ecosystem partners extend the action set by publishing their own actions. These are packaged as container images with a standard entry point, versioned independently, and invoked via the `uses:` step kind in workflow YAML. Current ecosystem actions include data queries (Space and Time), price feeds (Pyth), compliance screening (Chainalysis), payments (Circle, Stripe), AI inference (Hyperbolic), caching (Redis), email delivery, and token transfers.

Workflows are defined in YAML using a syntax compatible with GitHub Actions:

```yaml
name: Cross-chain settlement
on:
  schedule:
    - cron: '*/5 * * * *'
jobs:
  settle:
    steps:
      - name: Query pending transactions
        uses: w3-io/w3-sxt-action@v1
        with:
          command: query
          sql: >
            SELECT * FROM transactions
            WHERE status = 'pending'

      - name: Screen for compliance
        uses: w3-io/w3-chainalysis-action@v1
        with:
          address: ${{ steps.query.outputs.sender }}

      - name: Execute settlement
        ethereum:
          action: call-contract
          network: ethereum
          params:
            to: "0x..."
            function: "settle(address,uint256)"
            args:
              - ${{ steps.query.outputs.sender }}
              - ${{ steps.query.outputs.amount }}
```

The GitHub Actions compatibility is deliberate. Developers already familiar with CI/CD workflows can write W3.io workflows without learning a new language. The YAML is compiled into a canonical form, hashed for on-chain provenance, and deployed to the validator network.

## The Three-Layer Data Architecture

W3.io separates data responsibilities across three layers, each optimized for its role.

**Layer 1: L1 Settlement.** The on-chain layer stores commitments, not data. The footprint is minimal: one cumulative root per epoch, plus contract state for the validator set and workflow registry. This keeps gas costs low while providing the anchor for cryptographic verification.

**Layer 2: Protocol Nodes.** Validators store everything. Full workflow execution traces, receipt storage, epoch accumulation, P2P consensus messages, and a write-ahead log for crash recovery. This layer is the evidence behind the Layer 1 commitments and serves as the data availability layer for proof generation.

**Layer 3: Index and Query.** An indexer watches Layer 1 events and reconstructs queryable views: workflow runs by namespace, by epoch, by action type. The CLI provides developer access to settlement status and proof export. The API layer supports MCP (Model Context Protocol) for AI agent integration.

## The Spine and Ribs

W3.io's settlement architecture is best understood as a spine with ribs.

```
The Spine: L1 Epoch Chain

  Epoch 0        Epoch 1        Epoch 2
  root: 0xaaa    root: 0xbbb    root: 0xccc
  prev: 0x000    prev: 0xaaa    prev: 0xbbb

The Ribs: Per-Run Hashchains

  Workflow A -- block 1 -- block 2 -- receipt
  Workflow B -- block 1 -- receipt
  Workflow C -- block 1 -- block 2 -- block 3 -- receipt
```

The **spine** is the L1 epoch chain. A sequential, immutable record of cumulative sparse merkle tree roots on-chain. Each epoch's root covers all workflow receipts across all namespaces ever settled, not just the current epoch. The chain of roots captures the full evolution of world state.

The **ribs** are individual workflow execution traces. Per-run hashchains of consensus blocks that branch off the spine. Each step in a workflow produces a block containing the step's inputs, outputs, executor identity, and the previous block's hash. When the workflow completes, the final block hash and metadata are compressed into a receipt. That receipt is inserted into the namespace's sparse merkle tree, which feeds into the global tree, which produces the epoch root committed to the spine.

Any workflow execution is provable against any epoch root that includes it. A verifier needs only the on-chain root, a receipt, and two merkle proofs (receipt-in-namespace, namespace-in-global) to confirm that a specific workflow executed with a specific result at a specific time. No re-execution required. No trust in the validator that ran it.
