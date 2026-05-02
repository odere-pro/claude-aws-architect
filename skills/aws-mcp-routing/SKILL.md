---
name: aws-mcp-routing
description: |
  **WORKFLOW SKILL** — Route MCP server requests for AWS knowledge, IaC,
  pricing, security, IAM, and CloudWatch. Apply selection rules,
  degraded-mode fallbacks, and per-server timeout budgets.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent needs to consult an AWS MCP server. That includes the orchestrator's grounding step, every L3 specialist's MCP call, and any rule that delegates to a server. Do not apply this skill for non-AWS knowledge; use the agent's own reasoning or a non-MCP source.

Trigger conditions:

- The agent must answer a factual AWS question (quota, API shape, region availability, ARN, pricing).
- The agent must validate a CloudFormation or CDK construct.
- The agent must check IAM least-privilege, security findings, or operational metrics.
- The agent's previous MCP call timed out or returned a 5xx and a fallback decision is required.
- The agent is about to issue a tool call whose name might breach the 64-character fully-qualified-tool-name limit; this skill verifies the resolved server key.

## Procedure

1. **Classify the request.** Determine which of the six categories the request belongs to: docs, IaC, cost, security review, IAM, or operations. The category determines the server.
2. **Select the server.** Consult `references/selection-rules.md` for the category-to-server mapping. Use the short identifier (`kb`, `iac`, `cost`, `sec`, `iam`, `cw`) defined in `.mcp.json`, never the descriptive logical name in tool calls.
3. **Select the tool.** Consult the per-server tool catalogue in `references/server-roster.md`. Pick the narrowest tool that satisfies the request. Wide tools (e.g. broad documentation search) waste the per-specialist MCP-call budget (8 calls for discovery, 12 for solution-architect, 16 for implementation).
4. **Issue the call within the timeout budget.** The per-server `timeoutMs` value in `.mcp.json` is the per-call budget; the agent's MCP-call budget is the per-invocation cap. Both must be respected.
5. **Handle response.** On success, capture the result. On timeout or 5xx, consult `references/degraded-modes.md` for the per-server fallback behaviour and emit the corresponding labelled marker in the agent's output.
6. **Record the citation.** Every successful MCP call must be recorded in the grounding ledger via the `aws-grounding-cache` skill, producing a `<server>:<short-key>` reference for use in `grounded-by` fields.

## Gotchas

- **Do not confuse `sec` (well-architected-security MCP) with `iam` (IAM MCP).** They serve different surfaces; `sec` returns WAF security findings and Security Hub triage, `iam` returns IAM read/simulate. Routing the wrong one yields irrelevant results and wastes budget.
- **Do not silently drop signal on MCP failure.** Every degraded response must be labelled in the merged orchestrator output; fallback behaviour is documented per server in `references/degraded-modes.md`.
- **Do not exceed the per-specialist MCP-call budget.** Discovery 8, solution-architect 12, implementation 16. Exhaustion escalates back to the orchestrator with a `budget-exhausted` marker.
- **Do not mix logical names with `.mcp.json` keys.** Tool calls must use the short keys (`kb`, `iac`, `cost`, `sec`, `iam`, `cw`); the descriptive names like `aws-knowledge` or `well-architected-security` are documentation references only.
- **Do not invoke `awslabs.*` packages directly.** All AWS interaction goes through the MCP server abstraction. Bypassing the abstraction breaks the grounding ledger and the timeout budget.
- **Do not skip the grounding-ledger write.** A successful MCP call without a ledger entry leaves the agent's claim unsourced; downstream `grounded-by` validation will fail.

## Boundaries

- This skill MUST NOT invoke the AWS CLI directly. AWS API access is exclusively through MCP servers in `.mcp.json`.
- This skill MUST NOT add new MCP servers to `.mcp.json` at runtime; the v0.1.0 server set is fixed at six.
- This skill MUST NOT call MCP servers in the v0.2 reserved list (named in `references/server-roster.md`) until they are wired with a version bump and an explicit decision record.
- This skill MUST NOT translate MCP errors into agent-side retries; degraded behaviour is per-server and must be surfaced, not papered over.
- This skill MUST NOT assume any MCP server is available outside its declared `timeoutMs`.

## Quality Checks

Before returning a routing decision, confirm:

- The selected server key matches one of `kb`, `iac`, `cost`, `sec`, `iam`, `cw`.
- The selected tool name appears in `tests/gates/cache/tools-<server>.txt`.
- The chosen tool would not breach the 64-character fully-qualified-tool-name limit unless the `<server>:<tool>` pair appears in `tests/gates/cache/known-overshoots.txt`.
- A grounding-ledger entry has been queued for any successful call.
- A degraded-mode marker is queued for any failed call, per `references/degraded-modes.md`.
- The per-specialist MCP-call budget is not exceeded by issuing this call.
