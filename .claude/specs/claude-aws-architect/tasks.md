---
feature: claude-aws-architect
created: 2026-05-02
updated: 2026-05-02
status: review
grounded-by:
  - kb:11a02bb1
  - iac:33c04dd3
---

# Tasks — claude-aws-architect (release-dogfood meta-spec)

The plugin's own implementation backlog. Every task traces back to
one or more acceptance criteria in `requirements.md` and to the
relevant agent contracts under `contracts/`.

## Conventions

- Task IDs are stable: `T-<NN>` ordered by intended sequence, matched
  to the §12 PR sequence in `docs/plan/PR-PLAN.md`.
- Status values: `todo`, `in-progress`, `blocked`, `done`.
- Done tasks (PRs already merged) keep their full traceability so the
  meta-spec doubles as a release ledger.

## Tasks

### T-01 — Author the L4 orchestrator agent

- Status: `done`.
- Traces to: AC-1, AC-2,
  `contracts/claude-aws-architect-orchestrator-agent.md`.
- Outputs: `agents/claude-aws-architect-orchestrator-agent.md`.
- Risks: depth-classification false negatives surface as silent
  shallow runs on full-depth prompts; mitigated by the explicit
  `--deep` override and the `sdlc-full-depth` fixture.
- Notes: PR 16 (scaffold) + PR 18 (discovery wiring) shipped this
  agent; full-depth fan-out completed in PR 19 + PR 21.

### T-02 — Author the three L3 specialists

- Status: `done`.
- Traces to: AC-2, AC-3,
  `contracts/claude-aws-architect-discovery-agent.md`,
  `contracts/claude-aws-architect-solution-architect-agent.md`,
  `contracts/claude-aws-architect-implementation-agent.md`.
- Outputs: `agents/claude-aws-architect-discovery-agent.md`,
  `agents/claude-aws-architect-solution-architect-agent.md`,
  `agents/claude-aws-architect-implementation-agent.md`.
- Risks: bundling four implementation responsibilities under one
  specialist defers the merge-contract validation to runtime data;
  v0.2 split-out planned.
- Notes: PRs 17, 19, 21 shipped these agents; gate 9 enforces the
  agent contract.

### T-03 — Wire the deterministic transcript harness

- Status: `done`.
- Traces to: AC-1, AC-2, AC-3, AC-4.
- Outputs: `tests/run-transcripts.sh`,
  `tests/transcripts/{vibe-shallow,sdlc-full-depth,merge-conflict,degraded-mcp,iteration-cap}/`.
- Risks: `--update-snapshots` is intentionally unimplemented at
  v0.1.0; live-model behaviour is asserted only by the dogfood gate
  (T-08).
- Notes: PR 3 (skeleton) + PR 18 (executor) + PR 20 (full fixture set).

### T-04 — Author the six AWS Well-Architected pillar skills

- Status: `done`.
- Traces to: AC-3 (per-pillar review block), AC-5, AC-6.
- Outputs: `skills/aws-waf-{operational-excellence,security,reliability,performance-efficiency,cost-optimization,sustainability}-skill/`.
- Risks: per-pillar checklist drift between skills; mitigated by the
  locked WAF-pillar conventions documented in the skills' shared
  Gotchas sections.
- Notes: PRs 10–15.

### T-05 — Author the four Workflow skills the agents consume

- Status: `done`.
- Traces to: AC-1, AC-2, AC-3, AC-4.
- Outputs: `skills/aws-{mcp-routing,spec-grounding,grounding-cache,sdlc-workflow,component-contract,layered-diagram}/`.
- Risks: skill-substrate iceberg — agents declaring dependencies on
  unauthored skills; controlled by the SPEC §13 substrate table.
- Notes: PRs 4–9.

### T-06 — Wire the install-safety gates and host scripts

- Status: `done`.
- Traces to: AC-1.
- Outputs: `scripts/{init,doctor,install,uninstall}.sh`,
  `tests/gates/gate-{01,13,30,31,32,33}.sh`.
- Risks: install round-trip non-determinism on macOS bash 3.2;
  asserted by the dirty-roundtrip and dryrun-matches-real gates.
- Notes: PR 27.

### T-07 — Capture the canonical example artefact set

- Status: `done`.
- Traces to: AC-3, AC-4 (read-only reference).
- Outputs: `templates/examples/order-processing-pipeline/` (full
  F5 + F6 surface plus the grounding ledger).
- Risks: example drift from the workflow's actual output; mitigated
  by re-capture from `tests/transcripts/sdlc-full-depth/`.
- Notes: PR 30.

### T-08 — Run the release-dogfood and produce this meta-spec

- Status: `in-progress` (this PR).
- Traces to: AC-7.
- Outputs: `.claude/specs/claude-aws-architect/{requirements,design,tasks}.md`,
  `.claude/specs/claude-aws-architect/diagrams.d2`,
  `.claude/specs/claude-aws-architect/contracts/*.md`,
  `.claude/specs/claude-aws-architect/.grounding-ledger.json` (gitignored
  in consumer projects per §H4; force-tracked here as a release
  reference per §H5).
- Risks: the release-dogfood gate (gate 34) is the v0.1.0 tag
  blocker; failure here pushes the tag.
- Notes: PR 31 — this PR.

## Validation tasks

- **V-01** — All 18 deterministic gates in §11.A PASS against this
  meta-spec.
- **V-02** — All five fixtures in `tests/transcripts/` PASS under
  `tests/run-transcripts.sh` in both `--validate` and `--execute`
  modes.
- **V-03** — The §13.G acceptance checks all hold:
  - `design.md` names every L3 specialist.
  - `contracts/` includes one contract per L3 specialist plus the
    orchestrator (4 contracts).
  - `diagrams.d2` carries every layer tag in §9.6.
  - `.grounding-ledger.json` contains ≥1 citation against
    `aws-knowledge` (`kb:`) MCP.
