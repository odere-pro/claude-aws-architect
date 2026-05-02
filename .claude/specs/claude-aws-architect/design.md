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
  - iam:55e06ff5
  - cw:66f07aa6
---

# Design — claude-aws-architect (release-dogfood meta-spec)

The plugin is a four-agent orchestration: an L4 orchestrator hands a
classified prompt either back to the user (shallow) or to up to three
L3 specialists in a single fan-out turn (full-depth). Each L3
specialist owns a specific section of the F5 + F6 artefact set and
writes through a merge contract surfaced in `## Open Questions`
when conflicts occur. Six AWS MCP servers (`kb`, `iac`, `cost`,
`sec`, `iam`, `cw`) provide grounded data.

## Architecture overview

- **Pattern**: orchestrated parallel fan-out with a deterministic
  merge contract; not a chain, not a swarm.
- **Boundary**: ingress is the `/aws` slash command; egress is the
  `.claude/specs/<feature>/` directory of artefacts plus the
  grounding ledger.
- **Region strategy**: not applicable to the plugin runtime
  (Claude Code runs in the user's terminal); applies to consumer
  designs the plugin produces.
- **Data classification**: the plugin handles user prompts which may
  contain confidential design intent; redaction policy in
  `skills/aws-grounding-cache/references/redaction-policy.md`
  governs the eight-pattern catalogue applied before any ledger write.

Reference the layered diagram at `diagrams.d2`:

- `c4-l1` — system context: user → plugin → AWS MCP servers.
- `c4-l2` — runtime containers: orchestrator, discovery,
  solution-architect, implementation.
- `c4-l3-orchestrator` — orchestrator internals.
- `c4-l3-discovery` — discovery internals.
- `c4-l3-solution-architect` — solution-architect internals.
- `c4-l3-implementation` — implementation internals.
- `seq-system`, `seq-component`, `seq-error` — sequence views.

## Components

Every L3 specialist named in §5.2 of SPEC-v4 has a contract here,
plus the L4 orchestrator. The contracts use the out-of-vocab markers
`claude-code-agent-l4` and `claude-code-agent-l3` per OQ-1 in
`requirements.md`.

- **claude-aws-architect-orchestrator-agent** — L4 entry point,
  parallel fan-out, merge contract enforcement, final assembly.
  See `contracts/claude-aws-architect-orchestrator-agent.md`.
- **claude-aws-architect-discovery-agent** — L3 specialist owning
  Discovery phase: requirements draft + grounding ledger entries.
  See `contracts/claude-aws-architect-discovery-agent.md`.
- **claude-aws-architect-solution-architect-agent** — L3 specialist
  owning Design phase: design choices, contracts, layered diagram,
  per-pillar review block. See
  `contracts/claude-aws-architect-solution-architect-agent.md`.
- **claude-aws-architect-implementation-agent** — L3 specialist
  owning the bundled IaC + cost ROM + IAM hygiene + test sketch
  responsibilities, with v0.2 split-out planned. See
  `contracts/claude-aws-architect-implementation-agent.md`.

## Design choices

- **Decision: bundled implementation specialist at v0.1.0**
  - Chosen: one `implementation-agent` covering IaC drafting, cost
    ROM, IAM hygiene, and test sketches.
  - Alternatives: four separate L3 specialists (`cdk-engineer`,
    `cost-engineer`, `security-engineer`, `test-engineer`).
  - Rationale: convergence over parallelism at v0.1.0 — running four
    specialists produces unproductive merge churn before the merge
    contract has been validated; defer the split to v0.2 once
    runtime data exists. SPEC-v4 §5.2 documents the planned split.
  - grounded-by: `kb:11a02bb1`

- **Decision: closed-vocab `kind` for component contracts**
  - Chosen: 21-value AWS-resource closed vocabulary at v0.1.0;
    non-AWS components (including Claude Code agents) live as
    informal notes in `design.md`.
  - Alternatives: open `kind` field with conventions; per-domain
    sub-vocabularies (AWS / non-AWS / Claude-substrate).
  - Rationale: closed vocab pins the contract lint at v0.1.0; the
    non-AWS gap is a known limitation surfaced in the Open Questions
    section rather than a silent stretch of the schema; v0.2 extension
    tracked.
  - grounded-by: `kb:22b03cc2`

- **Decision: deterministic transcript replay over live model in CI**
  - Chosen: `tests/run-transcripts.sh` validates fixtures in
    `--validate` mode by default, executes the §5.6 routing
    deterministically in `--execute` mode without a live model.
  - Alternatives: live-model CI runs against pinned snapshots.
  - Rationale: reproducibility and cost discipline — live-model CI
    runs are non-deterministic and incur per-run cost. The
    deterministic harness covers the routing and merge contracts;
    live-model behaviour is asserted separately by the dogfood gate.
  - grounded-by: `iac:33c04dd3`

- **Decision: single MIT license, no telemetry, descriptive trademark posture**
  - Chosen: MIT, zero telemetry, descriptive use of "AWS" and
    "Well-Architected" with the `## Trademark notice` README
    block.
  - Alternatives: dual license (MIT + Apache); minimal anonymous
    usage telemetry; trademark-licensed listing.
  - Rationale: SPEC-v4 §15 declares the open posture; telemetry
    would conflict with the on-device trust boundary; trademark
    licensing requires AWS authorisation outside the plugin's scope.
  - grounded-by: `kb:22b03cc2`

## Per-pillar review

### Operational excellence

- Status: PASS.
- Top finding: every agent file ships nine canonical H2 sections in
  fixed order and is asserted by gate 9; `tests/run-transcripts.sh`
  exits non-zero on the first fixture mismatch and surfaces a
  diagnostic snapshot for both `--validate` and `--execute` modes.

### Security

- Status: PASS.
- Top finding: two PreToolUse hooks default-on (`secret-scanner`,
  `aws-api-write-guard`) plus four PostToolUse hooks default-off
  cover the full §7.2 hook surface; the `aws-api-write-guard`
  41-verb classifier blocks every AWS API write at the MCP boundary
  before the call leaves the host.

### Reliability

- Status: PASS.
- Top finding: every MCP server in `.mcp.json` carries a pinned
  version and a `timeoutMs`; the nightly mcp-version-skew workflow
  surfaces drift idempotently via a single tracked issue.

### Performance efficiency

- Status: PASS.
- Top finding: skills cap at 500 lines per `SKILL.md` (gate 17);
  hot path content lives under `references/<topic>.md` so
  invocation tokens stay bounded.

### Cost optimization

- Status: PASS.
- Top finding: zero recurring infrastructure cost — the plugin runs
  inside Claude Code on the consumer's machine; only consumer-side
  AWS API call costs apply, all read-class at v0.1.0.

### Sustainability

- Status: PASS.
- Top finding: no idle compute, no scheduled batch warmers, no
  background workers; every workflow turn is user-initiated.

## Open questions

- **OQ-1** — see `requirements.md` OQ-1: the contract `kind`
  vocabulary does not yet describe Claude Code agents. Resolved
  via the out-of-vocab markers in this PR; v0.2 schema bump
  tracked.

## Degraded signals

- `kind-vocab-extension-pending` — propagated from OQ-1; cleared by
  the v0.2 schema PR that extends the closed vocabulary to cover
  Claude Code agents.
