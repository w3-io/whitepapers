# Workflows

## Declarative Syntax

W3.io workflows are defined in YAML using the same syntax as GitHub Actions. This is not a loose compatibility. The W3.io compiler parses the same grammar, supports the same expression language, and handles the same structural elements: jobs, steps, conditionals, environment variables, secrets, outputs, and step references.

A developer who has written a GitHub Actions workflow can write a W3.io workflow without learning anything new. The difference is what happens after deployment. A GitHub Actions workflow runs on a centralized runner. A W3.io workflow runs on a distributed validator network with BFT consensus on every step.

The following example shows a non-trivial workflow that monitors an Ethereum wallet for large inbound transfers, screens the sender for sanctions compliance, logs the event to a database for audit, and sends a notification. It uses four ecosystem partners (Chainalysis for compliance, Space and Time for data, a Redis cache for deduplication, and an email action for alerting) alongside native Ethereum actions.

```yaml
name: Large transfer compliance monitor
on:
  schedule:
    - cron: '*/5 * * * *'
jobs:
  monitor:
    steps:
      - name: Check recent transfers
        id: transfers
        uses: w3-io/w3-sxt-action@v1
        with:
          command: query
          sql: >
            SELECT tx_hash, from_address, value
            FROM ethereum.erc20_transfers
            WHERE to_address = '${{ secrets.WATCHED_WALLET }}'
            AND value > 10000000000
            AND block_timestamp > NOW() - INTERVAL '5 MINUTES'

      - name: Deduplicate against cache
        id: dedup
        if: steps.transfers.outputs.row_count > 0
        uses: w3-io/w3-redis-action@v1
        with:
          command: sismember
          url: ${{ secrets.REDIS_URL }}
          key: processed-transfers
          value: ${{ steps.transfers.outputs.rows[0].tx_hash }}

      - name: Screen sender address
        id: compliance
        if: steps.dedup.outputs.result == '0'
        uses: w3-io/w3-chainalysis-action@v1
        with:
          address: ${{ steps.transfers.outputs.rows[0].from_address }}

      - name: Log to audit trail
        if: steps.compliance.outputs.risk != 'sanctions'
        uses: w3-io/w3-sxt-action@v1
        with:
          command: execute
          sql: >
            INSERT INTO compliance_log
            (tx_hash, sender, amount, risk_level, checked_at)
            VALUES ('${{ steps.transfers.outputs.rows[0].tx_hash }}',
                    '${{ steps.transfers.outputs.rows[0].from_address }}',
                    ${{ steps.transfers.outputs.rows[0].value }},
                    '${{ steps.compliance.outputs.risk }}',
                    NOW())

      - name: Mark as processed
        uses: w3-io/w3-redis-action@v1
        with:
          command: sadd
          url: ${{ secrets.REDIS_URL }}
          key: processed-transfers
          value: ${{ steps.transfers.outputs.rows[0].tx_hash }}

      - name: Alert on high risk
        if: steps.compliance.outputs.risk == 'high'
        uses: w3-io/w3-email-action@v1
        with:
          to: compliance@example.com
          subject: >
            High risk transfer detected:
            ${{ steps.transfers.outputs.rows[0].tx_hash }}
```

Every step in this workflow executes on a different validator, selected by consensus. The compliance check result, the database write, and the alert are all attested by the committee and included in the settlement receipt. An auditor can later prove that the compliance check happened, what it returned, and when, by verifying the receipt against the on-chain epoch root.

A second example shows composability across four partners where money actually moves. A treasury application must disburse USDC to a recipient, but only after verifying the stablecoin peg is stable, the recipient passes sanctions screening, and every decision is logged to an immutable audit trail.

```yaml
name: Compliant stablecoin disbursement
on:
  workflow_dispatch:
    inputs:
      recipient_address:
        description: 'Recipient wallet address'
        required: true
      amount_usd:
        description: 'Disbursement amount in USD'
        required: true
jobs:
  disburse:
    steps:
      - name: Check peg stability
        id: peg
        uses: w3-io/w3-pyth-action@v1
        with:
          feed: USDC/USD
          max_deviation_bps: 10

      - name: Screen recipient
        id: screening
        if: steps.peg.outputs.within_band == 'true'
        uses: w3-io/w3-chainalysis-action@v1
        with:
          address: ${{ inputs.recipient_address }}

      - name: Log decision to audit trail
        if: steps.screening.outputs.risk != 'sanctions'
        uses: w3-io/w3-sxt-action@v1
        with:
          command: execute
          sql: >
            INSERT INTO disbursement_log
            (recipient, amount_usd, risk_level, peg_rate)
            VALUES ('${{ inputs.recipient_address }}',
                    ${{ inputs.amount_usd }},
                    '${{ steps.screening.outputs.risk }}',
                    ${{ steps.peg.outputs.rate }})

      - name: Execute disbursement
        if: steps.screening.outputs.risk != 'sanctions'
        uses: w3-io/w3-circle-action@v1
        with:
          action: transfer
          destination: ${{ inputs.recipient_address }}
          amount: ${{ inputs.amount_usd }}
          currency: USDC
```

Before a single dollar moves, the workflow confirms the USDC peg is within 10 basis points of par (Pyth), verifies the recipient is not sanctions-listed (Chainalysis), writes the decision to a tamper-proof audit log (Space and Time), and only then executes the transfer (Circle). If any step fails, nothing moves. The settlement receipt proves not just that the payment happened, but that the peg check and sanctions screen happened first, in that order, with those results.

Each partner made this possible by contributing one ingredient. Space and Time did not need to know about Circle. Pyth did not need to know about Chainalysis. Each partner published their capability once. The recipe assembles them. When a fifth partner joins the ecosystem, every existing recipe can add a step without any of the other partners changing anything.

A workflow definition includes:

- **Name**: human-readable identifier for the workflow
- **Trigger** (`on:`): the event that initiates execution
- **Jobs**: one or more named job blocks, each containing a sequence of steps
- **Steps**: ordered operations within a job, each invoking an action or running a command
- **Environment** (`env:`): key-value pairs scoped to the workflow, job, or individual step
- **Secrets**: sensitive values fetched at runtime from a secrets provider, never stored in the workflow definition

## Triggers

Every workflow begins with a trigger. W3.io supports four trigger types.

**Cron schedule** (`schedule`). Time-based triggers that fire on a cron expression. A workflow triggered every five minutes, every hour, or once a day. The cron expression follows standard POSIX syntax. Useful for batch processing, periodic data aggregation, and scheduled reporting.

```yaml
on:
  schedule:
    - cron: '*/5 * * * *'
```

**RPC dispatch** (`workflow_dispatch`). On-demand triggers fired by an API call. A user, an application, or an AI agent sends a request to the W3.io RPC endpoint with optional input parameters. The workflow runs once with the provided inputs. Useful for user-initiated actions like deploying a contract, processing a payment, or running an analysis.

```yaml
on:
  workflow_dispatch:
    inputs:
      token_address:
        description: 'Token to analyze'
        required: true
      chain:
        description: 'Blockchain network'
        default: 'ethereum'
```

**Chain events**. Blockchain event triggers that fire when a specific on-chain event occurs. An ERC-20 transfer, a contract deployment, a governance vote. The validator network monitors the specified chain for matching events and initiates the workflow when one is detected. Currently supported for Ethereum and Solana.

**Oracle feeds**. External data triggers based on oracle price updates or threshold crossings. When a Pyth price feed crosses a defined boundary, the workflow fires. Useful for automated trading, liquidation monitoring, and alerts.

## Step Kinds

Each step in a workflow invokes one of five step kinds.

**Run** (`run:`). Executes a shell command inside an isolated container. The command runs in a Docker container with a defined image, environment variables, and mounted volumes. Output is captured from stdout and parsed as step outputs. This is the most flexible step kind, suitable for custom logic, data transformation, and any operation not covered by a specialized action.

```yaml
- name: Process data
  run: |
    echo "Processing ${{ steps.query.outputs.count }} records"
    python3 transform.py --input data.json
```

**Uses** (`uses:`). Invokes a published action by reference. The action is identified by its namespace, name, and version. Inputs are passed via the `with:` block. Outputs are available to subsequent steps via `${{ steps.<id>.outputs.<key> }}`. This is how ecosystem partner capabilities are accessed.

```yaml
- name: Query blockchain data
  id: query
  uses: w3-io/w3-sxt-action@v1
  with:
    command: query
    sql: SELECT * FROM ethereum.transactions LIMIT 10
```

**Ethereum** (`ethereum:`). Native blockchain operations on Ethereum and EVM-compatible chains. Supports balance queries, token transfers and approvals, contract deployment and calls, event queries, NFT operations, and ENS name resolution. The `network` parameter selects the target chain.

```yaml
- name: Check balance
  ethereum:
    action: get-balance
    network: ethereum
    params:
      address: "0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18"
```

**Solana** (`solana:`). Native blockchain operations on Solana. Supports balance queries, token account lookups, program invocation, SOL and SPL token transfers, and transaction monitoring.

**Bitcoin** (`bitcoin:`). Native blockchain operations on Bitcoin. Supports balance queries, UTXO management, fee estimation, and transaction construction.

## Expressions and Data Flow

W3.io's expression engine evaluates dynamic values at runtime using the `${{ }}` syntax. Expressions can reference:

- **Step outputs**: `${{ steps.query.outputs.result }}` accesses a named output from a previous step
- **Inputs**: `${{ inputs.token_address }}` accesses a trigger input parameter
- **Environment**: `${{ env.API_KEY }}` accesses an environment variable
- **Secrets**: `${{ secrets.PRIVATE_KEY }}` accesses a secret value (redacted in logs)
- **Job context**: `${{ job.status }}` reflects the current job state

The expression language supports functions for string manipulation (`contains`, `startsWith`, `endsWith`, `format`), data conversion (`toJSON`, `fromJSON`), and status checks (`success()`, `failure()`, `always()`).

Data flows between steps through outputs. Each step can produce named outputs that subsequent steps reference by step ID. This creates a typed data pipeline where each step receives exactly the data it needs from previous steps, without shared mutable state.

## Conditionals and Failure Handling

Steps can be conditionally executed using the `if:` field.

```yaml
- name: Alert on failure
  if: failure()
  uses: w3-io/w3-email-action@v1
  with:
    to: ops@example.com
    subject: Workflow failed
```

The `continue-on-error` field controls whether a step failure stops the workflow or allows subsequent steps to execute. Combined with status check functions (`success()`, `failure()`, `always()`), this enables error handling patterns like cleanup operations, fallback logic, and notification on failure.

Each step has a configurable timeout via `timeout-minutes`. If a step exceeds its timeout, the execution backend terminates it and the step is marked as failed. The default timeout is 10 minutes. The effective timeout for any step is the minimum of the step's configured timeout and the remaining time in the job's overall timeout.

## Compilation and Deployment

Workflow YAML is not interpreted directly by validators. It goes through a compilation pipeline.

**Parse**: the YAML is parsed into an abstract syntax tree. Structural errors (invalid keys, missing required fields, malformed expressions) are caught here.

**Validate**: semantic validation checks type consistency, expression references, step ID uniqueness, and action compatibility. Invalid expression references (referencing a step that doesn't exist, or an output that an action doesn't produce) are caught before deployment.

**Compile**: the validated AST is compiled into a canonical form. Comments, formatting, and whitespace are stripped. The result is a deterministic representation of the workflow's semantic content.

**Hash**: the compiled form is hashed. This `definition_hash` is the workflow's identity for settlement purposes. Two workflows with identical semantics but different formatting produce the same hash. The hash is stored on-chain in the WorkflowRegistry contract, creating an immutable link between the deployed workflow and its on-chain provenance.

**Deploy**: the compiled workflow is distributed to the validator network. Validators store the definition and begin monitoring for the specified trigger events.
