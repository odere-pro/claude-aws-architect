---
component: claude-aws-architect-implementation-agent
kind: claude-code-agent-l3
version: 0.1.0
status: review
talks-to:
  - claude-aws-architect-orchestrator-agent
  - claude-aws-architect-solution-architect-agent
grounded-by:
  - iac:33c04dd3
  - cost:44d05ee4
  - iam:55e06ff5
  - cw:66f07aa6
---

## Purpose

L3 specialist owning the bundled Implementation phase at v0.1.0:
IaC drafting, cost ROM, IAM hygiene, and acceptance-test sketches.
Reads `design.md` as read-only input, queries the `iac` / `cost`
/ `iam` / `cw` MCP servers, and writes the IaC / Cost / Security /
Acceptance / Observability sections of every contract plus the
whole-file `tasks.md`. v0.2 will split this specialist into
`cost-engineer`, `security-engineer`, and `test-engineer` once the
merge contract has runtime data.

## Interface

### Inputs

- Channel: orchestrator `Agent` call with `requirements.md`,
  `design.md`, and the partial `contracts/<slug>.md` files
  attached.
- Encoding: Markdown.

### Outputs

- Channel: return-value to the orchestrator.
- Encoding: `contracts/<slug>.md` IaC / Cost / Security /
  Acceptance / Observability sections plus `tasks.md` whole file.

### Errors

- `BudgetExhausted` — per-call budget of 12 MCP reads exceeded.
- `CostRomOnly` — `cost` MCP returns price data but the design
  cannot meet the cost envelope; surfaced as a marker rather than a
  silent advance.
- `IamAdvisoryOnly` — wildcard IAM policy unavoidable in the
  current draft; surfaced as a marker; the policy is left as a
  read-only carve-out only.
- `ObservabilityIncomplete` — `cw` recommended-alarms call returns
  fewer alarms than the contract requires; marker carried forward.
- `ValidationAdvisory` — `iac:validate_cloudformation_template`
  returns warnings that block status `accepted`; warnings logged.
- `TraceabilityMissing` — at least one `tasks.md` task lacks an
  `AC-N` trace; rejected before return rather than silently merged.

## Sequence

See `seq-component` in `diagrams.d2`. Happy path: intake design →
parallel MCP probes (iac validate, cost price, iam simulate, cw
alarms) → section-merge writes per contract → tasks.md whole-file
write with traceability → return.

## Component view (C4 L3)

References `c4-l3-implementation` in `diagrams.d2`. Look for the
four-server fan to `iac` / `cost` / `iam` / `cw`, each feeding its
own section of the contract through the section-merger before the
tasks-writer closes the turn.

## Acceptance criteria

- Every contract section authored by this agent ends only after
  the matching pillar skill records PASS / DEFER / GAP.
- Single-source MCP discipline: IaC section uses `iac` only, Cost
  section uses `cost` only, Security section uses `iam` only,
  Observability section uses `cw` only.
- MCP tool budget ≤ 12 calls per invocation.
- Wildcard IAM is rejected outside the read-only carve-out; the
  `iam-advisory-only` marker is the only legitimate exception path.
- IaC repo path:
  `agents/claude-aws-architect-implementation-agent.md`.

## Observability

### Metric

- One stderr line per MCP server probed, with the per-server call
  count and per-server budget remaining; surfaces budget pressure
  before exhaustion.

### Log

- Structured per-section log with the matching pillar gate
  outcome; the log is the canonical record for the per-pillar
  review block written by the solution-architect.

### Trace

- The grounding ledger captures every `iac` / `cost` / `iam` /
  `cw` lookup; trace stitching by `correlation` field across
  ledger entries.

## Integration points

- **claude-aws-architect-orchestrator-agent** — protocol: parent
  `Agent` call; payload is the design phase artefact set; return
  is the Implementation phase artefact set.
- **claude-aws-architect-solution-architect-agent** — protocol:
  section-merge handoff via the orchestrator; this agent never
  calls the solution-architect directly. Section ownership is
  declared explicitly: Purpose / Interface / Integration belong to
  the solution-architect; IaC / Cost / Security / Acceptance /
  Observability belong here.
