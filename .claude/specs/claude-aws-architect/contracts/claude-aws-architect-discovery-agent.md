---
component: claude-aws-architect-discovery-agent
kind: claude-code-agent-l3
version: 0.1.0
status: review
talks-to:
  - claude-aws-architect-orchestrator-agent
grounded-by:
  - kb:11a02bb1
  - kb:22b03cc2
---

## Purpose

L3 specialist owning the Discovery phase. Reads the user prompt
plus any session-visible context, queries the `kb` MCP server for
AWS knowledge needed to ground the requirements draft, writes
ledger entries, and returns a `requirements.md` draft to the
orchestrator. Never writes IaC, never writes contracts.

## Interface

### Inputs

- Channel: orchestrator `Agent` call with the classified prompt.
- Encoding: prompt text plus optional override flags.

### Outputs

- Channel: return-value to the orchestrator.
- Encoding: `requirements.md` Markdown draft plus a list of new
  ledger entries to merge into `.grounding-ledger.json`.

### Errors

- `BudgetExhausted` — the per-call budget of 8 MCP reads is
  exceeded; specialist returns a partial requirements draft with a
  `budget-exhausted` marker.
- `GroundingDeferred` — the `kb` MCP server returns 5xx; specialist
  returns a draft with a `grounding-deferred` marker and skips the
  ledger entry rather than fabricating one.

## Sequence

See `seq-component` in `diagrams.d2`. Happy path: parse intent →
issue `kb` reads (≤8) → write ledger entries via the
grounding-cache skill → draft `requirements.md` with one
`grounded-by` per acceptance criterion → return.

## Component view (C4 L3)

References `c4-l3-discovery` in `diagrams.d2`. Look for the
intent-parser → kb-reader → grounding-writer →
requirements-drafter chain; no other MCP server is touched.

## Acceptance criteria

- Every acceptance criterion in the returned `requirements.md`
  carries ≥1 `<server>:<short-key>` citation.
- MCP tool budget ≤ 8 calls per invocation.
- Single MCP server: `kb` only. Reaching for any other server is a
  Boundaries violation.
- IaC repo path: `agents/claude-aws-architect-discovery-agent.md`.
- Test coverage minimum: the `sdlc-full-depth` fixture asserts the
  Discovery turn shape.

## Observability

### Metric

- The agent emits one line per MCP call to the session transcript
  with the field `mcpCallIndex` so budget overruns are visible
  inline.

### Log

- Structured stderr per phase transition (intent-parser →
  kb-reader → grounding-writer → requirements-drafter) with
  consistent field names.

### Trace

- The grounding ledger entries written during this turn are the
  trace artefact; the ledger schema in
  `skills/aws-grounding-cache/references/ledger-schema.md` defines
  the canonical entry shape.

## Integration points

- **claude-aws-architect-orchestrator-agent** — protocol: single
  parent `Agent` call; payload is the classified prompt; return is
  the `requirements.md` draft plus ledger merges. No retries — the
  orchestrator decides on iteration after merge contract
  evaluation.
