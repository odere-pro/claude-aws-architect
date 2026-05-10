# Degraded modes

Loaded on demand by the `aws-mcp-routing` skill. Encodes the per-server fallback behaviour. Every degraded response must be labelled in the merged orchestrator output; silent drops are forbidden.

## Labelled markers

When an MCP call fails or times out, the agent emits a marker in its response. The marker is a short tag the orchestrator's merge contract surfaces in the final user-facing output. Markers are case-sensitive.

| Marker                     | Meaning                                                                                                                                                    |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `grounding-deferred`       | A factual claim could not be grounded; the assertion is held and surfaced as needing re-fetch.                                                             |
| `validation-advisory`      | An IaC validation step degraded to advisory mode; the contract still emits but the validation result is incomplete.                                        |
| `cost-rom-only`            | Pricing API was unreachable; the cost estimate is a rough order of magnitude with explicit uncertainty.                                                    |
| `security-checklist-only`  | Automated security assessment was unavailable; the security review falls back to a human-readable checklist.                                               |
| `iam-advisory-only`        | IAM least-privilege loop degraded to advisory; the policy is not auto-shrunk.                                                                              |
| `observability-incomplete` | CloudWatch evidence could not be retrieved; observability triple is flagged incomplete.                                                                    |
| `mcp-disabled-<server>`    | The MCP server is declared in `.mcp.json` but disabled in the consumer's settings (distinct from a runtime failure). User action is required to enable it. |

## Per-server failure handling

### `kb` — aws-knowledge

- **Symptom**: HTTP 5xx, timeout, rate limit (429).
- **Action**: discovery agent emits `grounding-deferred` on the affected claim. Orchestrator surfaces the marker. The claim is held in the ledger as `degraded` with the original query so it can be re-fetched on the next session.
- **Do not**: substitute the agent's pretrained knowledge for the missing citation. Pretrained AWS facts are out-of-date; the marker is the truthful signal.

### `iac` — aws-iac

- **Symptom**: stdio process timeout (60s budget), validation crash, schema mismatch.
- **Action**: IaC validation step downgrades to advisory. Component contract still emits, with the affected validation section labelled `validation-advisory`. The implementation agent surfaces the marker so a human can re-run validation manually.
- **Do not**: skip generating the contract because validation failed. The contract is still useful; only the validation section is degraded.

### `cost` — aws-pricing

- **Symptom**: pricing API unreachable, stdio timeout.
- **Action**: cost-engineer (v0.2) emits a ROM range with `cost-rom-only`. The user is told the estimate is rough and the upstream API was unavailable.
- **Do not**: invent dollar figures. ROM ranges are factor-of-two approximations based on cached pricing in the grounding ledger; if no cached pricing exists, the marker is the only acceptable output.

### `sec` — well-architected-security

- **Symptom**: stdio timeout, GuardDuty/Security Hub backend unavailable.
- **Action**: security-engineer (v0.2) emits checklist-only output with `security-checklist-only`; surfaces "automated assessment unavailable" alongside the checklist items the agent could verify by other means.
- **Do not**: assert "no findings" when the call failed. The absence of returned findings is not the same as the absence of findings.

### `iam` — iam

- **Symptom**: stdio timeout, missing IAM permissions on the caller's principal.
- **Action**: the IAM rule that consumes this server becomes advisory only; the least-privilege loop is deferred. Marker `iam-advisory-only`.
- **Do not**: emit a permissive policy as a fallback. Advisory output documents what the policy SHOULD do; the human applies the change.

### `cw` — cloudwatch

- **Symptom**: stdio timeout, log-insights query timeout, alarm-history pagination failure.
- **Action**: test-engineer (v0.2) emits unit-test design only; observability triple flagged `observability-incomplete`.
- **Do not**: synthesise metric data. The observability triple's missing metric is a real signal — the deployment may need additional instrumentation before observability is achievable.

## `mcp-disabled-<server>` — user-action-required, not runtime failure

This marker is distinct from the runtime-failure markers above. It fires
when the skill detects that the MCP server's tools (`mcp__<server>__*`)
are not present in the session's available tool list, indicating the
server is either disabled in the consumer's `.claude/settings*.json`
(`disabledMcpjsonServers`) or never approved via `/mcp`.

- **Symptom**: `mcp__<server>__<tool>` returns "tool not found" or is
  absent from the available tool list at session start.
- **Action**: skill emits `mcp-disabled-<server>` once per affected
  server, with remediation copy:
  > MCP `<server>` is declared in `.mcp.json` but not enabled in this
  > session. Run `/mcp` to approve, remove the server from
  > `disabledMcpjsonServers` in `.claude/settings.json`, or run
  > `/aws-doctor` for a full health report. The dependent recipe will
  > degrade until the server is enabled.
- **Do not**: treat as a transient failure (do NOT emit
  `grounding-deferred`, `cost-rom-only`, etc. in its place). The user
  has to take an action; a transient marker would mislead them into
  waiting for the server to recover.
- **Do not**: emit one marker per call. One marker per server, per
  session, with the remediation copy.

The `aws-mcp-availability` UserPromptSubmit hook (default-off, opt-in)
surfaces the same signal proactively at prompt time, before any skill
attempts a call. When the hook is enabled, the skill marker remains
the catch-all for cases where the server was enabled at session start
but became unavailable mid-session.

## Marker lifecycle in the merge contract

1. Specialist agent issues an MCP call.
2. Call fails or times out.
3. Specialist emits the appropriate marker (above) in its returned output.
4. Orchestrator receives the specialist's output, identifies the marker, and propagates it into the merged response under a `## Degraded signals` section.
5. The user sees the marker and the affected claim. The orchestrator's merge contract requires that every specialist signal — including degraded ones — appears either in `## Open Questions` or in the conflict-resolution log. None are silently dropped.

## Retry policy

The plugin does NOT retry MCP calls automatically at v0.1.0. Reasons:

- Retries hide upstream instability and inflate the per-specialist MCP-call budget.
- The 30s and 60s timeouts already account for a single network round-trip.
- The user's next session can re-attempt the call once the MCP server's transient issue clears; held claims in the ledger flag exactly what to re-fetch.

A v0.2+ enhancement could add a single bounded retry (e.g., one retry on 5xx with exponential back-off capped at 5s), gated by an explicit decision record. Until then: no retries.
