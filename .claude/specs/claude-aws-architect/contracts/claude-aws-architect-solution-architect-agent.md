---
component: claude-aws-architect-solution-architect-agent
kind: claude-code-agent-l3
version: 0.1.0
status: review
talks-to:
  - claude-aws-architect-orchestrator-agent
  - claude-aws-architect-implementation-agent
grounded-by:
  - kb:11a02bb1
  - iac:33c04dd3
---

## Purpose

L3 specialist owning the Design phase. Reads the requirements draft
plus session context, queries the `kb` and `iac` MCP servers,
authors the per-pillar review block via the six WAF pillar skills,
writes the Purpose / Interface / Integration sections of every
`contracts/<slug>.md` and the `c4-l1` / `c4-l2` layers of
`diagrams.d2`. Hands the IaC / Cost / Security / Acceptance /
Observability sections off to `implementation-agent` via the
section-merge contract.

## Interface

### Inputs

- Channel: orchestrator `Agent` call with `requirements.md`
  attached.
- Encoding: requirements draft Markdown plus override flags.

### Outputs

- Channel: return-value to the orchestrator.
- Encoding: `design.md`, `contracts/<slug>.md` partial sections
  (Purpose / Interface / Integration only), `diagrams.d2`
  c4-l1/c4-l2 layers, per-pillar review block.

### Errors

- `BudgetExhausted` — per-call budget of 12 MCP reads exceeded;
  partial design returned with `budget-exhausted` marker.
- `GroundingDeferred` — propagated from a degraded `kb` or `iac`
  server.
- `PillarGap` — one or more pillar checklists report `GAP`; the
  marker is carried into the per-pillar review block in
  `design.md`, never silently set to PASS.

## Sequence

See `seq-component` in `diagrams.d2`. Happy path: intake
requirements → probe `iac` for component shape → run each pillar
skill against the candidate design → author contracts and diagrams
→ return.

## Component view (C4 L3)

References `c4-l3-solution-architect` in `diagrams.d2`. Look for
the intake → iac-reader → pillar-skills → contract-author →
diagram-author chain; pillar-skills sits in the middle so each
contract section closes with a per-pillar gate applied.

## Acceptance criteria

- Every component named in `design.md` has a matching
  `contracts/<slug>.md` file populated through Purpose / Interface
  / Integration.
- `design.md` per-pillar review block carries a status
  (PASS / DEFER / GAP) for every one of the six WAF pillars.
- MCP tool budget ≤ 12 calls per invocation.
- IaC repo path:
  `agents/claude-aws-architect-solution-architect-agent.md`.
- Test coverage minimum: the `sdlc-full-depth` and `merge-conflict`
  fixtures both exercise this agent's output shape.

## Observability

### Metric

- One stderr line per pillar gate transition (PASS / DEFER / GAP)
  per contract section; visible in the session transcript.

### Log

- Structured per-section authoring log; the
  `aws-component-contract` skill's section-by-section invariants
  drive the log format.

### Trace

- The grounding ledger captures every `kb` and `iac` lookup; the
  trace tree is reconstructed by reading
  `.grounding-ledger.json` in chronological order.

## Integration points

- **claude-aws-architect-orchestrator-agent** — protocol: parent
  `Agent` call; payload is the requirements draft; return is the
  Design phase artefact set.
- **claude-aws-architect-implementation-agent** — protocol:
  section-merge handoff via the orchestrator's merge contract;
  this agent owns Purpose / Interface / Integration in
  `contracts/<slug>.md`, the implementation agent owns IaC / Cost
  / Security / Acceptance / Observability. No direct call between
  the two specialists.
