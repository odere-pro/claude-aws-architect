---
feature: claude-aws-architect
created: 2026-05-02
updated: 2026-05-02
status: review
grounded-by:
  - kb:11a02bb1
  - kb:22b03cc2
  - iac:33c04dd3
  - cost:44d05ee4
---

# Requirements — claude-aws-architect (release-dogfood meta-spec)

A Claude Code plugin that runs the AWS Well-Architected SDLC as a
single `/aws` command: from a vibe prompt, the orchestrator routes to
shallow direct answers or escalates to a parallel fan-out across
discovery, solution-architect, and implementation specialists who
together produce the F5 + F6 artefact set under `.claude/specs/<feature>/`.
This meta-spec is the plugin run against itself per SPEC-v4 §1.3 and
the release-dogfood acceptance check per §13.G.

## Context

- Greenfield single plugin, MIT licensed; ships with six pinned AWS
  MCP servers (`kb`, `iac`, `cost`, `sec`, `iam`, `cw`) and no
  proprietary dependencies.
- Target user is an engineer holding AWS account credentials in their
  Claude Code session who wants to design an AWS feature with the
  Well-Architected pillars enforced by default.
- Out of scope at v0.1.0: live AWS API writes, multi-cloud, plugin
  authoring workflows for downstream consumers.

## User stories

- As an engineer, I want to invoke `/aws` with a vibe prompt and
  receive a `requirements.md`, `design.md`, `tasks.md`,
  `diagrams.d2`, and per-component contracts under `contracts/<slug>.md`,
  so that the SDLC artefact set is produced in one pass.
- As an engineer, I want the plugin to ground every factual AWS claim
  with a `<server>:<short-key>` citation in `.grounding-ledger.json`,
  so that I can re-derive the source without re-running the prompt.
- As a release engineer, I want the plugin to design itself end-to-end
  before the v0.1.0 tag, so that the dogfood gate proves the plugin
  is ready to design any consumer system.

## Acceptance criteria

- **AC-1** — `/aws` accepts a free-form prompt and routes deterministically
  by §5.6 depth-classification; `--deep` and `--quick` overrides are
  respected.
  - grounded-by: `kb:11a02bb1`
- **AC-2** — Full-depth runs fan out to ≥2 specialists in a single
  orchestrator turn via parallel `Agent` calls.
  - grounded-by: `kb:11a02bb1`
- **AC-3** — Every artefact required by F5 and F6 is produced under
  `.claude/specs/<feature>/` on a full-depth run.
  - grounded-by: `kb:22b03cc2`
- **AC-4** — Every `requirements.md` acceptance criterion carries
  ≥1 `grounded-by` entry; the matching ledger entry parses against
  the schema in `skills/aws-grounding-cache/references/ledger-schema.md`.
  - grounded-by: `kb:22b03cc2`
- **AC-5** — IaC pre-deployment validation is exercised on the
  generated `design.md` via the `iac` MCP server before any
  contract advances past status `draft`.
  - grounded-by: `iac:33c04dd3`
- **AC-6** — Cost ROM stays within the consumer-declared cost ceiling
  in `claude-aws-architect.local.md`; the implementation agent
  surfaces a `cost-rom-only` marker if the ceiling is unreachable
  rather than silently advancing.
  - grounded-by: `cost:44d05ee4`
- **AC-7** — The plugin successfully designs itself: this meta-spec
  passes every gate in §11.A and §11.B per the §11.E gate 34 release
  blocker.
  - grounded-by: `kb:11a02bb1`

## Non-functional requirements

- **Reliability**: deterministic transcript replay across all five
  fixtures in `tests/transcripts/`.
- **Security**: no secret leaves the local repo; `aws-secret-scanner`
  hook intercepts on `Write|Edit|MultiEdit|NotebookEdit`;
  `aws-api-write-guard` hook intercepts on `mcp__.*` write verbs.
- **Cost envelope**: consumer-declared in
  `claude-aws-architect.local.md`; not fixed by the plugin.
- **Compliance**: MIT license, descriptive trademark posture,
  declarative deletion of telemetry per SPEC-v4 §15.

## Constraints and assumptions

- **Constraint**: every MCP server in `.mcp.json` is pinned by
  exact version per §16.2.
- **Constraint**: no live AWS API writes from inside the workflow;
  enforced by `aws-api-write-guard` and the implementation agent's
  Boundaries.
- **Assumption**: consumer has `uvx`, `jq`, and `aws` CLIs available
  per the `doctor.sh` preflight.

## Out of scope

- Multi-region active-active in the orchestrator's own design.
- v0.2 specialists (`cost-engineer`, `security-engineer`,
  `test-engineer`) — they split out of `implementation-agent` once
  the merge contract is validated under load.
- Bedrock and IaC-foundations powers — deferred to v0.2.

## Open questions

- **OQ-1**: the closed `kind` vocabulary in
  `skills/aws-component-contract/references/contract-schema.md`
  enumerates AWS resource kinds only and does not yet describe
  Claude Code agents. The contracts in this meta-spec use the
  out-of-vocab markers `claude-code-agent-l4` and
  `claude-code-agent-l3`, surfaced as a degraded signal in
  `design.md`. v0.2 schema bump tracks under §13.G's stated
  failure-handling clause.
