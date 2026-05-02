# Phases and depth heuristic

Loaded on demand by the `aws-sdlc-workflow` skill. Defines the five SDLC phases the orchestrator drives, and the depth-escalation heuristic that decides shallow vs full for any incoming prompt.

## The five phases

| Phase     | Trigger                                               | What it produces                                                   | Specialist set (full depth)                     |
| --------- | ----------------------------------------------------- | ------------------------------------------------------------------ | ----------------------------------------------- |
| Vibe      | Sub-second routing; every prompt enters here.         | Depth classification (shallow or full).                            | None.                                           |
| Discovery | Prompt classified as full + no `requirements.md` yet. | `requirements.md` (draft) + `.grounding-ledger.json` entries.      | discovery agent.                                |
| Design    | `requirements.md` exists at `draft` or later.         | `design.md` + `contracts/<slug>.md` per component + `diagrams.d2`. | solution-architect agent.                       |
| Plan      | `design.md` at `accepted` (or `review` with --force). | `tasks.md` + per-component IaC/cost/observability filled in.       | implementation agent.                           |
| Validate  | Pre-acceptance lint pass; runs on demand or in CI.    | Lint reports; no new artefacts.                                    | None — gate scripts and per-instructions rules. |

## Phase ordering

- Vibe → Discovery → Design → Plan → Validate is the canonical forward direction.
- Validate can run after any phase to catch regressions; it does not have to wait until Plan.
- A phase can be re-entered by reopening the corresponding artefact (e.g., re-edit `requirements.md` to bump it back to `draft`); the downstream phases must be re-run because their assumptions may have shifted.

## Depth heuristic

The orchestrator classifies every incoming prompt as **shallow** or **full**. Shallow answers from grounded knowledge with citations and writes no artefacts. Full fans out specialists in parallel and writes the artefacts for the active phase.

Apply these rules in order; stop at the first match:

1. **Explicit override.** If the prompt contains `--deep`, use full depth. If it contains `--quick`, use shallow depth. Skip remaining rules.
2. **SDLC-artefact intent.** If the prompt names any of: `design`, `architecture`, `IaC`, `CDK`, `threat model`, `cost estimate`, `security review`, `runbook`, `spec`, `requirements`, `contract`, `RFC`, `ADR` → full depth.
3. **Verb-of-creation.** If the prompt opens with one of: `build`, `design`, `architect`, `propose`, `draft`, `spec`, `plan` AND names an AWS service or noun → full depth.
4. **Verb-of-inquiry.** If the prompt opens with one of: `what`, `how`, `which`, `is`, `does` → shallow depth. Unless a follow-up matches rule 2 or 3, no fan-out happens.
5. **Default.** Shallow depth.

The heuristic is **content-classified**, not length-classified. A one-line prompt naming "design" still escalates to full depth; a long prompt that is purely a question stays shallow.

**Rule precedence callout**: rule 2 takes precedence over rule 4 because it is listed first. A prompt that opens with "how", "what", "which", "is", or "does" but _also_ names an SDLC-artefact keyword (e.g., "How should we **design** the payments service?", "What **architecture** should we use for X?") still escalates to full depth — the SDLC-artefact intent fires before the verb-of-inquiry has a chance to. This is intentional: the user signalled they want a design, not just an answer; the question form is incidental.

## Mid-turn re-evaluation

Shallow → full escalation can happen mid-turn if the user clarifies in a way that matches rule 2 or 3. The new prompt fragment is evaluated against the heuristic; if it now matches a full-depth rule, the orchestrator escalates and runs the discovery/design/plan flow.

Full → shallow downgrade does NOT happen automatically. Once the orchestrator has invoked specialists at full depth, the merge proceeds and the artefacts are produced. A user who wants a follow-up to be shallow must explicitly say so (or pass `--quick` on the next turn).

## Phase responsibilities

### Vibe

- Single, deterministic, sub-second classifier.
- No MCP calls.
- Output: depth (shallow or full), and if full, the active phase based on which artefacts already exist.

### Discovery

- Owned by the discovery agent.
- Reads only `aws-knowledge` MCP server.
- Writes `requirements.md` with at least one `grounded-by` citation per acceptance criterion.
- Maintains the per-feature grounding ledger via `aws-grounding-cache`.

### Design

- Owned by the solution-architect agent.
- Reads `aws-knowledge` and `aws-iac`.
- Writes `design.md`, one `contracts/<slug>.md` per component, and `diagrams.d2` with all required layer tags.
- Consults all six WAF pillar skills for design-time review.

### Plan

- Owned by the implementation agent.
- Reads `aws-iac`, `aws-pricing`, `iam`, `cloudwatch`.
- Fills the IaC, Cost, Security, Acceptance, and Observability sections of each contract.
- Writes `tasks.md` with the implementation breakdown.

### Validate

- No agent owner; deterministic gates and per-instructions rules.
- Fails if any artefact's lint check fails or any cross-artefact consistency rule is violated.
- Runs in CI on every PR and on demand via `bash tests/gates/run-all.sh`.

## What the depth heuristic does NOT cover

- Authentication and authorisation: out of scope; the orchestrator inherits whatever the user's session provides.
- Multi-feature workflows: the orchestrator handles one feature per turn; multi-feature prompts are split by the user or the orchestrator escalates back asking which to handle first.
- Background or asynchronous work: every fan-out is in-turn; there is no notion of a job queue at v0.1.0.
