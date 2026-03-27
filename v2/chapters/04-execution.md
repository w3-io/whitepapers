# Execution

## The Separation of Concerns

W3.io's execution model separates **what** to execute from **how** to execute it. The workflow runtime decides what happens at each step: which action to invoke, what inputs to pass, how to parse the outputs. The execution backend decides how it happens: which container to run, how to enforce timeouts, how to handle failures.

This separation is implemented through two traits in the codebase.

The **Syscalls** trait defines five operations that the runtime can invoke: `run` (shell commands), `uses` (published actions), `ethereum`, `solana`, and `bitcoin` (native chain operations). The runtime calls these without knowing anything about the underlying execution infrastructure.

The **Backend** trait defines two operations that the syscalls layer delegates to: `prepare` (make the execution environment ready) and `execute` (run a command and return the result). The backend handles isolation, timeouts, resource management, and cleanup.

Today, W3.io ships with a Docker backend. The architecture is designed so that a Firecracker backend (microVM isolation) or a WASM backend can be added without changing the runtime or the syscalls layer.

## Docker Execution

When a validator is selected to execute a workflow step, the Docker backend handles the full lifecycle.

**Preparation.** The backend pulls the required container image (if not already cached) and prepares the execution environment. Image pulls are deduplicated across concurrent workflows. If two workflows need the same image at the same time, only one pull happens.

**Container naming.** Each container gets a deterministic name based on the workflow's trigger hash, job ID, step index, and a timestamp. This makes containers identifiable in Docker logs, and it means the backend can kill a specific container by name if the process becomes unresponsive.

**Execution.** The step's command runs inside the container with the workflow's environment variables, secrets (injected via a temporary env file that is deleted after startup), and any required filesystem mounts. Standard output and standard error are captured as the step's log output.

**Timeout enforcement.** Every step has a timeout (configurable via `timeout-minutes:`, default 10 minutes). The backend uses `tokio::select!` with fair polling to race the step execution against a deadline. If the deadline fires first, the backend initiates a shutdown sequence:

1. Send SIGTERM to the Docker process (Docker forwards this to the container's PID 1)
2. Drain stdout and stderr during a 10-second grace period (prevents pipe deadlock where a process writing during shutdown blocks on full pipes)
3. If the process hasn't exited after the grace period, send SIGKILL
4. Unconditionally call `docker kill` by container name as a final defense

This escalation ensures that a hung container never blocks consensus indefinitely. The step is marked as failed with a timeout error, and the workflow's failure handling logic (continue-on-error, if conditions) determines what happens next.

**Output parsing.** After execution completes, the backend parses the container's output. Step outputs (key-value pairs written to a designated output file inside the container) are extracted and made available to subsequent steps via the expression engine. Environment modifications (variables written to the environment file) are merged into the workflow's environment for downstream steps.

## Step Identity

Every execution carries typed identity fields that flow from the consensus layer through the entire call chain: the trigger hash (which workflow run), the job ID (which job within the run), and the step index (which step within the job). These fields appear in every backend log line, making it possible to trace a specific step's execution across container logs, P2P messages, and consensus records using the same identifiers.

This is not just a debugging convenience. The step identity is part of the settlement receipt. The trigger hash, combined with the step index, uniquely identifies a specific step execution within the protocol's history. When a receipt is verified against an on-chain epoch root, the step identity ties the cryptographic proof to a specific observable event.

## Future Backends

The Backend trait is designed to support execution environments beyond Docker.

**Firecracker.** Firecracker microVMs provide stronger isolation than containers. Each step would execute in its own lightweight VM, booted in milliseconds, with a dedicated kernel. The `prepare` method would handle VM boot and filesystem setup. The `execute` method would run the command inside the VM. This is the planned path for production workloads where stronger isolation is required.

**WASM.** WebAssembly runtimes offer sandboxed execution without the overhead of containers or VMs. A WASM backend would compile actions to WASM modules and execute them in a sandboxed runtime. This is a longer-term consideration for lightweight actions where container startup overhead is disproportionate to the computation.

Both future backends would implement the same `prepare` and `execute` interface. The runtime, the consensus layer, and the settlement layer would not change. Only the isolation boundary moves.
