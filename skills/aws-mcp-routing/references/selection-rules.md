# Selection rules

Loaded on demand by the `aws-mcp-routing` skill. Maps the agent's intent to the correct server and tool. Every routing decision must be auditable; this file is the authoritative source of that mapping.

## Category-to-server mapping

| Intent category                                                                                | Server | Notes                                                                   |
| ---------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------- |
| Factual AWS knowledge — quotas, API shape, region availability, ARN format, What's New         | `kb`   | The default landing point for any factual claim.                        |
| CloudFormation or CDK validation, scanning, sample retrieval                                   | `iac`  | Includes pre-deploy compliance and synth analysis.                      |
| Pricing API queries, ROM cost estimation, Bedrock cost patterns                                | `cost` | The cost-engineer (v0.2) and implementation specialist consume this.    |
| Security pillar reviews, GuardDuty / Security Hub triage, encryption posture, network exposure | `sec`  | Pillar-level security analysis.                                         |
| IAM read or simulate, least-privilege loop, role/policy enumeration                            | `iam`  | Distinct from `sec`. Mutations gated by hook.                           |
| CloudWatch alarms, log queries, metric data                                                    | `cw`   | Post-deploy observability evidence; never used for design-time choices. |

## Tool-selection priorities

When multiple tools on the same server could answer the request:

1. **Prefer the narrowest tool.** A targeted query (e.g. read a specific doc page) costs one MCP call; a broad search costs more and consumes the per-specialist budget (8 calls for discovery, 12 for solution-architect, 16 for implementation).
2. **Prefer cached lookups.** If the answer is in the grounding ledger and the entry is within its TTL (pricing 30 days, quotas 30 days, API shapes 90 days, region 90 days, ARN indefinite), skip the MCP call entirely.
3. **Prefer read tools over mutate tools.** All v0.1.0 use cases are read-only. Any tool that would mutate AWS state (e.g. `iam.create_role`, `iam.delete_user`) is gated by the `aws-api-write-guard` hook and must not be called by autonomous agents at v0.1.0.

## Conflict resolution between servers

Some questions could plausibly route to more than one server:

- **"Will this CDK app fit my budget?"** → call `cost.analyze_cdk_project` first (it parses the synth output and consults pricing). Do NOT call `iac.search_cdk_documentation` in parallel for the same question; that wastes the budget.
- **"Is this S3 bucket policy safe?"** → call `sec.CheckStorageEncryption` for encryption state and `iam.simulate_principal_policy` for access simulation. These are complementary, not duplicative.
- **"What service should I use for X?"** → start with `kb.recommend`, then drill into the chosen service via the relevant pillar tool.

## Pre-call checks

Before issuing any MCP call:

1. The selected server's key appears in `.mcp.json#mcpServers`.
2. The selected tool name appears in `tests/gates/cache/tools-<server>.txt`.
3. The fully-qualified `mcp__plugin_<plugin>_<server>__<tool>` length is < 64 characters, OR the `<server>:<tool>` pair appears in `tests/gates/cache/known-overshoots.txt` (in which case the call is permitted but flagged in the ledger).
4. The agent's MCP-call budget has not been exhausted.

## Post-call obligations

After every successful MCP call:

1. Insert a `<server>:<short-key>` entry in the grounding ledger via `aws-grounding-cache`, with the canonicalised query, retrieved timestamp, result summary, and TTL class.
2. Cite the entry as `<server>:<short-key>` in any `grounded-by` field that consumes the result.

After every failed MCP call:

1. Consult `degraded-modes.md` for the per-server fallback.
2. Emit the labelled marker in the agent's response.
3. Log the failure as a `degraded` entry in the grounding ledger so the orchestrator's merge contract can surface it.
