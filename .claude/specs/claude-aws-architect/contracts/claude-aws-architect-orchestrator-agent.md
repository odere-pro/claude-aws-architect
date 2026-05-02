---
component: claude-aws-architect-orchestrator-agent
kind: claude-code-agent-l4
version: 0.1.0
status: review
talks-to:
  - claude-aws-architect-discovery-agent
  - claude-aws-architect-solution-architect-agent
  - claude-aws-architect-implementation-agent
grounded-by:
  - kb:11a02bb1
  - kb:22b03cc2
---

## Purpose

The L4 entry point for `/aws`. Classifies the user prompt by §5.6
depth-classification rules, routes shallow prompts to a direct
answer, and routes full-depth prompts to a single-turn parallel
fan-out across the three L3 specialists. Owns the merge contract
that resolves specialist disagreements per §5.5 and writes the
final-assembly artefacts under `.claude/specs/<feature>/`.

## Interface

### Inputs

- Channel: `/aws` slash command argument and any session state
  visible to Claude Code.
- Encoding: free-form prompt text plus optional `--deep` /
  `--quick` overrides.

### Outputs

- Channel: writes to `.claude/specs/<feature>/`.
- Encoding: Markdown for spec artefacts, D2 for diagrams, JSON for
  the grounding ledger.

### Errors

- `IterationCapReached` — orchestrator halts at the cap
  configured by `max-iterations` and surfaces an
  `iteration-cap-reached` marker in `## Open Questions` rather than
  looping.
- `MergeUnresolvable` — when §5.5 priority rules cannot resolve a
  conflict, surfaced under `## Open Questions` with both options.
- `BudgetExhausted` — propagated from a specialist hitting its
  per-call budget; the orchestrator continues with partial returns
  and surfaces a `budget-exhausted` marker.

## Sequence

See `seq-component` and `seq-error` in `diagrams.d2`. Happy path:
classify → dispatch (single-message multi-`Agent` calls) → collect
returns → enforce merge contract → assemble → write.

## Component view (C4 L3)

References `c4-l3-orchestrator` in `diagrams.d2`. Look for the
classifier → fanout → merge → assembler chain; the assembler is the
only writer to the final-assembly paths.

## Acceptance criteria

- Single-turn parallel fan-out: ≥2 specialist `Agent` calls in one
  orchestrator turn on full-depth prompts.
- Iteration cap honoured: zero un-bounded loops across every
  fixture in `tests/transcripts/`.
- IaC repo path: `agents/claude-aws-architect-orchestrator-agent.md`.
- Test coverage minimum: every routing rule in §5.6 has at least
  one transcript fixture asserting it.

## Observability

### Metric

- `tests/run-transcripts.sh --execute` exit code is the canonical
  rollup; non-zero indicates a routing or merge violation.

### Log

- The orchestrator emits structured stderr lines on every routing
  decision and every merge-contract application; logs land in the
  Claude Code session transcript with the `correlation` field set
  to the prompt hash.

### Trace

- The grounding ledger doubles as the trace target for any
  specialist that touches an MCP server; the orchestrator does not
  call MCP servers directly.

## Integration points

- **claude-aws-architect-discovery-agent** — single `Agent` call on
  full-depth Discovery turns; returns a `requirements.md` draft and
  ledger entries.
- **claude-aws-architect-solution-architect-agent** — single
  `Agent` call on full-depth Design turns; returns `design.md`,
  `contracts/<slug>.md` Purpose/Interface/Integration sections, and
  the `c4-l1`/`c4-l2` diagram layers.
- **claude-aws-architect-implementation-agent** — single `Agent`
  call on full-depth Implementation turns; returns
  `contracts/<slug>.md` IaC/Cost/Security/Acceptance/Observability
  sections plus `tasks.md`.
