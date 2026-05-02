# Plan v4: `claude-aws-architect` — Declarative Specifications

> **Clean-room rule:** every spec below is _declarative_. It names the artefact, its required fields, its required sections, the constraints those sections must satisfy, and the verifiable post-conditions. **No example bodies, no sample bash, no sample JSON values, no sample EARS sentences, no sample feature names.** Implementation is left to the build phase from this spec alone.
>
> **Changes from v3:** §1.6 compatibility and operational budgets (Claude Code version target, MCP timeouts, orchestrator iteration cap); §11.A new deterministic gates 16–18 (description quality, SKILL.md line budget, tool-name length budget); §13 promotes the dogfood meta-spec to a release gate; §16 security and supply chain; §17 release and support model. Out-of-scope items recorded in §18 to prevent re-litigation.
>
> **Changes from v2:** §0.2 name locked as `claude-aws-architect`; §13 substrate backlog expanded to include all 6 WAF pillar skills at v0.1.0; §15 covers license (MIT), telemetry policy (none), marketplace listing strategy, and trademark disclaimer.
>
> **Changes from v1:** §0 distribution model, §1.5 scope discipline, §3.5 degraded modes, §4.3 mandatory Gotchas section, §5.5 merge contract, §5.6 escalation triggers, §10 transcript-replay harness, §11 verification gates split into deterministic and runtime, §12 PR-sized execution sequence, §13 substrate authoring backlog.

---

## 0. Distribution model and naming

### 0.1 Distribution model

The plugin ships as a **single greenfield Claude Code plugin** under a new repository (`claude-aws-architect`). It does not extend, depend on, or migrate from any existing AWS-skills marketplace. Greenfield model implies:

- No backward-compatibility surface.
- No migration notes (v1 §13 is dropped).
- All substrate skills are authored within this plugin (see §13).
- The plugin's `plugin.json` declares a single name; the Powers mechanism (§9.1) is the only composition surface inside the plugin.

### 0.2 Name

**Locked: `claude-aws-architect`.**

Rationale (against the screening criteria from v2):

- Specific enough — "AWS architect" is a recognised role; users searching for AWS SDLC tooling find it.
- Generic enough — "architect" covers design, IaC, cost, security, and test concerns without the sub-brand collision risk of "well-architected" (an AWS programme name) or "solutions" (an AWS job title and certification track).
- Short — 21 chars, ergonomic as a repo name and install target. The slash-command stem is `/aws`, not the plugin name.
- Available — to be verified at repo-creation time on GitHub and on every index listed in §15.3.
- Trademark posture — "AWS" appears as a descriptive token, not a leading claim of affiliation. The README ships the disclaimer in §15.4.

Throughout this plan, `claude-aws-architect` is the literal plugin name. It appears in `plugin.json`, install paths (`.claude/plugins/claude-aws-architect/`), Power filenames (`claude-aws-architect-cdk.power.json`), agent filenames (`claude-aws-architect-orchestrator-agent.md`), and the user-facing settings file (`.claude/claude-aws-architect.local.md`).

---

## 1. Plugin requirements

### 1.1 Functional

- F1. One L4 orchestrator agent (`claude-aws-architect-orchestrator-agent`) is the single entry point exposed via `/aws`.
- F2. Orchestrator fans out L3 specialists in parallel — single message, multiple `Agent` tool invocations — and merges results into one response per the merge contract in §5.5.
- F3. Depth is on-demand (no mode toggle): vibe summary → parallel fan-out → grounded artefacts → validation, escalating per the triggers in §5.6.
- F4. Every **factual** AWS claim (API shape, quota, pricing, service availability, region presence, ARN format) cites ≥1 AWS MCP source. **Design opinions** (architectural choices, trade-offs, recommendations) require a rationale paragraph linking to a WAF pillar or named principle, not a citation.
- F5. Each generated component ships with a contract: interface, sequence diagram, C4 L3 fragment, acceptance criteria, observability triple, integration links.
- F6. One `diagrams.d2` per feature carries every required layer tag (§9.6) — C4 L1, L2, L3, plus three sequence-diagram zoom levels.
- F7. Plugin ships **3 Powers** at v0.1.0 (declarative MCP+skills+hooks+commands bundles): `claude-aws-architect-cdk`, `claude-aws-architect-cost`, `claude-aws-architect-security`. Two additional Powers (`claude-aws-architect-bedrock`, `claude-aws-architect-iac-foundations`) deferred to v0.2.
- F8. Plugin ships **3 commands** at v0.1.0: `/aws`, `/aws-spec`, `/aws-doctor`. Six additional commands (`/aws-power`, `/aws-hook`, `/aws-doc`, `/aws-price`, `/aws-quota`, `/aws-sec-scan`, `/aws-cdk-check`) deferred to v0.2 pending usage data.
- F9. Plugin ships **12 new L2 skills** at v0.1.0 covering the orchestrator's substrate (6 workflow skills) and full WAF pillar coverage (6 pillar skills). See §13 for the authoring backlog. Two additional new skills (`aws-hook-authoring`, `aws-power-authoring`) deferred to v0.2.
- F10. Plugin ships an opt-in **hooks registry** (`hooks/hooks.json`) gated by `.claude/claude-aws-architect.local.md`; default-enabled hooks limited to `aws-secret-scanner` and `aws-api-write-guard`.
- F11. Plugin ships a **doctor script** and an **init script** for one-command setup (§8).
- F12. Plugin ships an **install script** with two modes (`--symlink` default, `--copy`); never overwrites existing consumer files.
- F13. Plugin ships an **uninstall script** that reverses the install without touching consumer-authored specs, contracts, steering, or hooks.
- F14. Plugin ships a **hook dispatcher** that resolves `hooks/hooks.json` against consumer settings and invokes matching hook scripts.
- F15. Plugin ships **1 L4 orchestrator + 3 L3 specialist agents** at v0.1.0 (§5): discovery, solution-architect, implementation. Three additional L3 specialists (cost-engineer, security-engineer, test-engineer) deferred to v0.2 pending merge-contract validation. Each agent declares MCP servers, skills, rules, sibling agents, and output paths in its Dependencies section.
- F16. Plugin ships **9 file-scoped instruction rules** (§6) under `claude-aws-architect/rules/` lifting accuracy of AWS code, IaC, SDK, CDK, tests, docs, and diagrams.
- F17. Plugin ships **2 quality-and-security hook scripts** in addition to operational hooks (§7.2): `aws-secret-scanner` and `aws-test-coverage`.
- F18. Plugin defines a **canonical agent declaration contract** (§5.1) that every agent file must satisfy.
- F19. Plugin defines a **canonical rule declaration contract** (§6.1) that every rule file must satisfy.
- F20. Plugin defines a **canonical skill declaration contract** (§4.3) that every new skill file must satisfy.
- F21. Plugin defines a **canonical hook script contract** (§7.3) that every hook script must satisfy.
- F22. Plugin wires **6 AWS MCP servers** at v0.1.0 (§3): `aws-knowledge`, `aws-iac`, `aws-pricing`, `well-architected-security`, `iam`, `cloudwatch`. Four additional servers deferred to v0.2 (`aws-api-mcp-server`, `bedrock-agentcore`, `dynamodb`, `aws-serverless`).

### 1.2 Non-functional

- N1. Portable: zero absolute paths anywhere; `command: "uvx"` resolved via PATH in `.mcp.json`.
- N2. Markdown + JSON + bash only — no TypeScript build at v0.1.0.
- N3. All substrate L1–L2 artefacts are authored within this plugin (see §13). No external host-repo dependencies.
- N4. YAML frontmatter on every agent/skill/command/rule file passes `yaml.safe_load`.
- N5. Each `powers/*.power.json` validates against the §9.1 schema.
- N6. Each `hooks/hooks.json` entry validates against the §9.2 schema.
- N7. README sections in this exact order: _Install · Quickstart · Commands · Powers · Hooks · Rules · Troubleshooting · Uninstall_.
- N8. SPEC.md sections in this exact order: _Architecture · MCP servers · Skills · Agents · Rules · Powers · Hooks · Schemas · Validation gates · Versioning_.
- N9. CHANGELOG starts at `v0.1.0`; SemVer; one entry per merged PR.
- N10. `init.sh`, `install.sh`, `uninstall.sh` are idempotent; never destructive without `--force`.
- N11. Cross-platform: macOS (zsh + brew) and Linux (bash + apt-get); Windows/WSL deferred. **CI matrix runs install/doctor/uninstall on `ubuntu-latest` and `macos-latest` for every PR touching `scripts/`.**
- N12. Minimum AWS IAM documented in README; reference `claude-aws-architect/skills/aws-iam-skill/references/minimum-iam-policy.json`.
- N13. Concurrency: parallel fan-out caps at **3** simultaneous specialist `Agent` calls per orchestrator turn at v0.1.0. Cap is sized to the v0.1.0 specialist count (§F15) and revisited when more specialists land. Justification: each parallel call competes for the same MCP server pool and rate-limits; 3 keeps p95 latency under the model-call ceiling observed in transcript-replay fixtures (§10).
- N14. Linters: every bash script passes `shellcheck`; every JSON file passes `jq -e .`; every YAML frontmatter passes `yaml.safe_load`; every Markdown passes `markdownlint-cli2 --config .markdownlint.jsonc` and `prettier --check`.
- N15. Grounding cache: MCP citations stored as `(server|short-key|retrieved-date)` references; payloads in `.claude/specs/<feature>/.grounding-ledger.json` (git-ignored). **TTL policy**: pricing 30 days, quotas 30 days, API shapes 90 days, region/availability 90 days, ARNs and immutable identifiers indefinite. Stale entries are flagged on read and re-fetched lazily.
- N16. **Short-key collision handling**: short-key is the first 8 hex chars of SHA-1 of the canonicalised query; on collision detection at write-time, extend to 12 hex chars for the colliding entry only.

### 1.3 Self-dogfood

- H1. The plugin's repository contains a `.claude/specs/claude-aws-architect/` directory holding the meta-spec — the plugin run against itself.
- H2. The repository's `CLAUDE.md` adds an entry-point section pointing to `/aws` and `claude-aws-architect/SPEC.md`.
- H3. The repository's `.claude/settings.json` appends one PreToolUse hook delegating to the plugin's hook dispatcher, gated by existence of `.claude/claude-aws-architect.local.md`.
- H4. `.gitignore` adds `.claude/claude-aws-architect.local.md` and `.claude/specs/**/.grounding-ledger.json`.
- H5. The smoke prompt from §10 produces a captured `claude-aws-architect/templates/examples/<feature>/` reference artefact, committed to the repo as the canonical executable reference §11 gates point at.

### 1.4 ADRs (separate PR)

- A1. `ADR-NNNN-aws-plugin-architecture.md` — 4-layer plugin architecture, vibe-first, AWS-knowledge-grounded.
- A2. `ADR-NNNN-component-contracts-as-deliverable.md` — every component ships with contract + sequence + C4 L3.
- A3. `ADR-NNNN-aws-mcp-server-roster.md` — rationale for the v0.1.0 server roster (§3.1) and the v0.2 expansion list (§3.2).
- A4. `ADR-NNNN-merge-contract.md` — rationale for the conflict-resolution priority order (§5.5).
- A5. `ADR-NNNN-escalation-heuristic.md` — rationale for the depth-escalation triggers (§5.6).
- A6. `ADR-NNNN-license-and-distribution.md` — rationale for MIT license, no-telemetry posture, delayed-listing strategy, and trademark disclaimer (§15).
- A7. `ADR-NNNN-supply-chain-and-release.md` — rationale for MCP version pinning, deferred code signing, single-version support model, and the dogfood-as-release-gate decision (§16, §17).
- A8. ADRs ship in their own `docs(adr)` PR; never bundled with feature commits.

### 1.5 Scope discipline

- S1. Every functional requirement above carries an explicit v0.1.0 / v0.2 / v1.0 tier. Items not tagged are v0.1.0 by default.
- S2. v0.2 promotion of any deferred item requires: (a) the v0.1.0 transcript-replay harness (§10) stays green for 30 days; (b) at least one external user has installed the plugin per §11.D1.
- S3. v0.1.0 ships only what §13's substrate authoring backlog can complete. Anything that cannot be substrated by §13 is automatically v0.2.

### 1.6 Compatibility and operational budgets

- O1. **Claude Code version target**: the plugin declares a minimum supported Claude Code version in `plugin.json#engines.claude-code` (SemVer range). v0.1.0 targets the latest stable Claude Code release at tag time. The README documents the tested version under `## Compatibility`.
- O2. **MCP server timeout policy**: every entry in `.mcp.json` declares a per-server `timeoutMs`. v0.1.0 defaults: HTTP servers (e.g. `aws-knowledge`) 30000ms; stdio servers performing read-only queries 30000ms; stdio servers performing validation/scan operations (`aws-iac`) 60000ms; stdio servers issuing AWS API calls (`iam`, `cloudwatch`) 30000ms. Timeouts are per-call, not per-session.
- O3. **Tool-name length budget**: the longest fully-qualified tool name (`mcp__plugin_<plugin>_<server>__<tool>`) must remain under 64 characters to satisfy Bedrock's tool-name limit. Shorter server identifiers are mandated where an unmodified package name would breach the budget; mappings are declared in `.mcp.json`.
- O4. **Orchestrator iteration cap**: the orchestrator agent declares a `max-iterations` value in its frontmatter — the maximum number of fan-out cycles per user turn before it halts and returns whatever it has with an `iteration-cap-reached` marker. v0.1.0 default: 3 iterations. Asserted in transcript-replay fixtures.
- O5. **Specialist MCP-call budget**: per §5.4, each L3 agent declares an MCP tool budget. v0.1.0 defaults: discovery 8 calls, solution-architect 12 calls, implementation 16 calls. Exhaustion escalates back to the orchestrator with a `budget-exhausted` marker, not silently truncated output.
- O6. **Conflict escalation visibility**: the §5.5 Open Questions section is the single user-facing surface for unresolved errors. The plan does not maintain a separate error catalogue; every named failure mode (timeout, budget exhaustion, iteration cap, MCP degraded, merge conflict) appears in Open Questions or in the grounding ledger's `conflict-resolution` log per §5.5.

---

## 2. Plugin folder layout

```text
claude-aws-architect/
├── .claude-plugin/plugin.json
├── .mcp.json                            §3 — 6 AWS MCP servers at v0.1.0 (pinned per §16.2)
├── .github/                             §17.2 — issue templates, PR template, workflows
│   ├── ISSUE_TEMPLATE/
│   ├── pull_request_template.md
│   ├── dependabot.yml                   §16.4 — Actions deps only at v0.1.0
│   └── workflows/
├── README.md
├── SPEC.md
├── CHANGELOG.md
├── SECURITY.md                          §16.1 — vulnerability disclosure
├── SUPPORT.md                           §17.3 — community support posture
├── LICENSE                              §15.1 — MIT
├── docs/
│   ├── threat-model.md                  §16.3
│   └── repo-polish-checklist.md         §18 — non-spec backlog items
├── agents/                              §5 — 1 L4 + 3 L3 specialists at v0.1.0
├── commands/                            §1 F8 — 3 commands at v0.1.0
├── skills/                              §4.2 — 12 new skills at v0.1.0
│   └── <name>/
│       ├── SKILL.md
│       ├── trigger-keywords.txt         §11.A gate 16 — description quality input
│       ├── references/
│       └── templates/
├── rules/                               §6 — 9 instruction files
├── powers/                              §1 F7 — 3 power bundles at v0.1.0
├── hooks/
│   ├── hooks.json
│   └── scripts/                         §7 — operational + quality + security hooks
├── templates/
│   ├── .claude/
│   │   ├── specs/<feature>/
│   │   └── claude-aws-architect.local.md.example
│   └── examples/                        captured smoke artefacts (§H5)
├── tests/
│   ├── transcripts/                     §10 — pinned prompt → tool-call snapshots
│   ├── install/                         §11.D — dirty-tree install/uninstall fixtures
│   └── matrix/                          §11 — cross-platform CI fixtures
└── scripts/                             §8 — init, doctor, install, uninstall
```

---

## 3. Layer 1 — MCP server roster

### 3.1 v0.1.0 roster (6)

Per O2, every server in `.mcp.json` carries a `timeoutMs` value and a pinned version (per §16.2). The version field is omitted from the table below; it lives in `.mcp.json` and is enforced by §11.A gate 12.

| #   | Package (uvx target)                           | Transport | Category   | Timeout (O2) | Purpose                                                 |
| --- | ---------------------------------------------- | --------- | ---------- | ------------ | ------------------------------------------------------- |
| 1   | `awslabs.aws-knowledge-mcp-server` (HTTP)      | http      | Docs       | 30000ms      | Latest AWS docs, API refs, What's New, WAF guidance     |
| 2   | `awslabs.aws-iac-mcp-server`                   | stdio     | IaC        | 60000ms      | CloudFormation/CDK validation, scanning, samples        |
| 3   | `awslabs.aws-pricing-mcp-server`               | stdio     | Cost       | 30000ms      | Pricing API + cost estimation                           |
| 4   | `awslabs.well-architected-security-mcp-server` | stdio     | Security   | 60000ms      | WAF security findings + GuardDuty/Security Hub triage   |
| 5   | `awslabs.iam-mcp-server`                       | stdio     | Security   | 30000ms      | First-class IAM read + simulate; least-privilege loop   |
| 6   | `awslabs.cloudwatch-mcp-server`                | stdio     | Operations | 30000ms      | Post-deploy observability evidence: alarms, log queries |

### 3.2 v0.2 candidates (4)

`awslabs.aws-api-mcp-server` (general AWS API operations — gated by §7 write-guard hooks reaching production stability) · `awslabs.amazon-bedrock-agentcore-mcp-server` (added with the `claude-aws-architect-bedrock` Power) · `awslabs.dynamodb-mcp-server` (added when a specialist agent needs authoritative DDB modeling) · `awslabs.aws-serverless-mcp-server` (SAM lifecycle, added with `claude-aws-architect-iac-foundations`).

### 3.3 Deferred (revisit at v0.3+)

`awslabs.aws-documentation-mcp-server` (offline mirror) · `awslabs.billing-cost-management-mcp-server` (chargeback) · `awslabs.lambda-tool-mcp-server` · `awslabs.stepfunctions-tool-mcp-server` · `mcp-proxy-for-aws`.

### 3.4 Skipped (out of scope)

Container-plane (`eks`, `ecs`, `finch`), non-DDB data planes (`postgres`, `mysql`, `aurora-dsql`, `documentdb`, `neptune`, `keyspaces`, `timestream-for-influxdb`, `redshift`, `s3-tables`, `iot-sitewise`, `appsync`), cache plane (`elasticache`, `valkey`, `memcached`), Bedrock subordinates (`bedrock-kb-retrieval`, `kendra-index`, `qbusiness-anonymous`, `qindex`, `bedrock-custom-model-import`, `sagemaker-ai`), niche (`sns-sqs`, `mq`, `aws-location`, `aws-support`, `openapi`), domain-specific (`healthomics`, `healthimaging`, `healthlake`), monitoring duplicate (`prometheus`), deprecated (`ccapi`).

### 3.5 Degraded modes

Per-server fallback when an MCP call fails or times out:

| Server                      | Failure mode  | Fallback behaviour                                                                                 |
| --------------------------- | ------------- | -------------------------------------------------------------------------------------------------- |
| `aws-knowledge`             | timeout / 5xx | Discovery agent emits a `grounding-deferred` marker on the claim; orchestrator surfaces it.        |
| `aws-iac`                   | timeout / 5xx | IaC validation step downgrades to advisory; component contract still emits.                        |
| `aws-pricing`               | timeout / 5xx | Cost-engineer (v0.2) emits ROM range with `grounding-deferred`; user is told it's an estimate.     |
| `well-architected-security` | timeout / 5xx | Security-engineer (v0.2) emits checklist-only output; surfaces "automated assessment unavailable". |
| `iam`                       | timeout / 5xx | IAM rule (§6) advisory only; least-privilege loop deferred.                                        |
| `cloudwatch`                | timeout / 5xx | Test-engineer (v0.2) emits unit-test design only; observability triple flagged incomplete.         |

All degraded responses are **labelled** in the merged orchestrator output. The orchestrator never silently drops a specialist's signal because of an MCP failure.

---

## 4. Layer 2 — Skills

### 4.1 Substrate authoring

This plugin is greenfield; it does not depend on host-repo skills. Every skill the orchestrator and L3 agents reference is authored in this plugin under `claude-aws-architect/skills/`. The v0.1.0 substrate authoring backlog is enumerated in §13.

### 4.2 New skills shipped by the plugin (12 at v0.1.0, 14 total)

Each skill lives at `claude-aws-architect/skills/<name>/SKILL.md` plus optional `references/` and `templates/`. Each skill must satisfy §4.3. The roster is split into **workflow skills** (1–6, agent-procedural) and **pillar skills** (7–12, AWS-knowledge-encoding).

#### Workflow skills (6)

| #   | Skill                    | Tier   | Purpose (declarative)                                                                                                                                  | Required references                                            | Required templates           | Invoked by                                     |
| --- | ------------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- | ---------------------------- | ---------------------------------------------- |
| 1   | `aws-sdlc-workflow`      | v0.1.0 | Drive the vibe → discovery → design → plan → validate procedure end-to-end; orchestrate parallel fan-out and merge.                                    | `phases.md`, `parallel-fanout.md`, `merge-rules.md`            | none                         | `claude-aws-architect-orchestrator-agent`      |
| 2   | `aws-spec-grounding`     | v0.1.0 | Enforce that every factual claim carries ≥1 grounded-by reference and every design opinion carries a rationale; flag both kinds of un-grounded claims. | `cite-format.md`, `grounded-by-rules.md`, `opinion-vs-fact.md` | none                         | Orchestrator, discovery agent, all writers     |
| 3   | `aws-grounding-cache`    | v0.1.0 | Maintain `.grounding-ledger.json`: insert, dedupe, expire (TTL per N15), redact secrets; provide short-key derivation with collision extension (N16).  | `ledger-schema.md`, `ttl-policy.md`, `collision-policy.md`     | `grounding-ledger.json.tmpl` | `aws-spec-grounding`                           |
| 4   | `aws-component-contract` | v0.1.0 | Author and lint per-component contract files (frontmatter + section ordering + observability triple + integration links).                              | `contract-schema.md`, `observability-triple.md`                | `contract.md.tmpl`           | Solution-architect, implementation, validators |
| 5   | `aws-layered-diagram`    | v0.1.0 | Author one `diagrams.d2` carrying every required layer tag (§9.6); lint orphans, untagged nodes, missing layers.                                       | `c4-and-sequence.md`, `layer-taxonomy.md`                      | `diagrams.d2.tmpl`           | Solution-architect                             |
| 6   | `aws-mcp-routing`        | v0.1.0 | MCP server selection per request: which server, which tool, fallback per §3.5, rate-limit handling.                                                    | `server-roster.md`, `selection-rules.md`, `degraded-modes.md`  | none                         | All agents                                     |

#### WAF pillar skills (6)

These encode pillar-specific review checklists, decision questions, and grounding shortcuts. Each pillar skill is content-heavy (review prompts, anti-patterns, design questions) and code-light. Honours the `claude-aws-architect` name's promise of full Well-Architected coverage.

| #   | Skill                                  | Tier   | Pillar                 | Purpose (declarative)                                                                                                                                                                                   | Required references                                                     | Required templates    | Invoked by                         |
| --- | -------------------------------------- | ------ | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | --------------------- | ---------------------------------- |
| 7   | `aws-waf-operational-excellence-skill` | v0.1.0 | Operational Excellence | Encode design questions, anti-patterns, and review checklists for OE pillar; flag missing runbooks, undefined SLOs, and absent observability triples.                                                   | `oe-design-questions.md`, `oe-antipatterns.md`, `oe-checklist.md`       | `oe-review.md.tmpl`   | Solution-architect, implementation |
| 8   | `aws-waf-security-skill`               | v0.1.0 | Security               | Encode design questions, anti-patterns, and review checklists for Security pillar; surface least-privilege violations, encryption gaps, identity-perimeter weaknesses, and incident-response gaps.      | `sec-design-questions.md`, `sec-antipatterns.md`, `sec-checklist.md`    | `sec-review.md.tmpl`  | Solution-architect, implementation |
| 9   | `aws-waf-reliability-skill`            | v0.1.0 | Reliability            | Encode design questions, anti-patterns, and review checklists for Reliability pillar; flag single-AZ deployments, missing retries, undefined recovery objectives, and absent failure-mode analysis.     | `rel-design-questions.md`, `rel-antipatterns.md`, `rel-checklist.md`    | `rel-review.md.tmpl`  | Solution-architect, implementation |
| 10  | `aws-waf-performance-efficiency-skill` | v0.1.0 | Performance Efficiency | Encode design questions, anti-patterns, and review checklists for PE pillar; flag inappropriate compute selection, missing caching layers, undefined latency targets, and absent load-testing strategy. | `pe-design-questions.md`, `pe-antipatterns.md`, `pe-checklist.md`       | `pe-review.md.tmpl`   | Solution-architect, implementation |
| 11  | `aws-waf-cost-optimization-skill`      | v0.1.0 | Cost Optimization      | Encode design questions, anti-patterns, and review checklists for Cost pillar; flag missing cost ceilings, absent right-sizing review, untagged resources, and ungoverned data-egress paths.            | `cost-design-questions.md`, `cost-antipatterns.md`, `cost-checklist.md` | `cost-review.md.tmpl` | Solution-architect, implementation |
| 12  | `aws-waf-sustainability-skill`         | v0.1.0 | Sustainability         | Encode design questions, anti-patterns, and review checklists for Sustainability pillar; flag inefficient data lifecycles, oversized fleets, and region choices misaligned with carbon footprint goals. | `sus-design-questions.md`, `sus-antipatterns.md`, `sus-checklist.md`    | `sus-review.md.tmpl`  | Solution-architect                 |

#### Deferred (v0.2)

| #   | Skill                 | Tier | Purpose (declarative)                                                                                                                                     | Required references                                               | Required templates                             | Invoked by                                                |
| --- | --------------------- | ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------- | --------------------------------------------------------- |
| 13  | `aws-hook-authoring`  | v0.2 | Generate hook script headers; lint exit-code contract; detect AWS write verbs; validate `hooks.json` entries (§9.2).                                      | `hook-events.md`, `aws-write-verbs.md`, `hook-script-contract.md` | `hook-script.sh.tmpl`, `hooks.json.entry.tmpl` | Plugin authors at build time; orchestrator at runtime     |
| 14  | `aws-power-authoring` | v0.2 | Validate `powers/*.power.json` (§9.1) and the plugin manifest (`plugin.json`); enforce name/version/description, MCP/skill/hook/command cross-references. | `power-schema.md`, `manifest-schema.md`                           | `power.json.tmpl`                              | Plugin authors at build time; `/aws-power` command (v0.2) |

`aws-bedrock-validation` and a test-design skill remain tracked under §4.4.

### 4.3 Canonical skill declaration contract

Each `SKILL.md` must declare:

**Frontmatter keys:**

| Key                         | Constraint                                                                                                                                                                                                                                                                              |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                      | Lowercase hyphenated; matches parent directory name.                                                                                                                                                                                                                                    |
| `description`               | Block scalar prefixed `**WORKFLOW SKILL** —`; states capabilities and trigger conditions; cites no example bodies. ≤300 chars. Must contain ≥3 distinct keywords from the skill's sibling `trigger-keywords.txt` per §11.A gate 16. Must not begin with `This skill` or `A skill that`. |
| `version`                   | SemVer.                                                                                                                                                                                                                                                                                 |
| `argument-hint` (optional)  | When the skill is `user-invocable`.                                                                                                                                                                                                                                                     |
| `user-invocable` (optional) | Boolean; default false.                                                                                                                                                                                                                                                                 |

**Required sibling files:**

- `trigger-keywords.txt` — newline-separated list of keywords this skill matches, used by §11.A gate 16 to validate description quality. The file is the skill author's declaration of what user prompts should fire this skill; CI cross-checks against the description.

**Body sections in this exact order:**

1. **When to Use** — declarative trigger conditions; no example feature names.
2. **Procedure** — numbered steps; each step names input, action, output. No example payloads.
3. **Gotchas** — bulleted list of Claude failure modes specific to this AWS surface, paired with the corrective behaviour. **Required, not optional**: this is the single highest-signal section in any AWS skill. No examples; just the failure mode and the corrective rule.
4. **Boundaries** — explicit "do not" rules.
5. **Quality Checks** — verifiable post-conditions.
6. **How It Differs** _(optional)_ — table comparing sibling skills (`Skill | Mode | Description`) when collisions exist.

**Body size budget:** total body length (excluding frontmatter) is ≤500 lines per Anthropic authoring guidance. Skills exceeding the budget split content into `references/<topic>.md` files (Claude loads references on-demand only). Enforced by §11.A gate 17.

**Forbidden:** example bodies, sample bash, sample JSON values, sample EARS sentences, sample feature names, sample payloads. References go under `references/<topic>.md`; templates go under `templates/<name>.tmpl` and may contain placeholder tokens only.

### 4.4 Gaps explicitly out of scope at v0.1.0

- Multi-account contract-test pattern (cross-account IAM/STS/AssumeRole) — defer to a future skill once a real-user need surfaces (§S2).
- Plugin marketplace listing validation — depends on Claude Code marketplace contract finalising.
- Synthetic-load and chaos-test plan generation — deferred.
- `aws-bedrock-validation` skill — deferred to v0.2 with the `claude-aws-architect-bedrock` Power.

---

## 5. Layer 3 — Agents

### 5.1 Canonical agent declaration contract

Every agent file under `claude-aws-architect/agents/<name>-agent.md` must declare:

**Frontmatter keys:**

| Key                | Constraint                                                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`             | Kebab-case; ends `-agent`; matches filename without `.md`.                                                                                              |
| `description`      | Block scalar with two halves — `USE FOR` (≥3 keyword-rich bullets) and `DO NOT USE FOR` (each bullet redirects to a named alternative). Total ≤8 lines. |
| `model`            | Workspace-approved model ID.                                                                                                                            |
| `effort`           | Advisory; one of `high`, `medium`, `low`.                                                                                                               |
| `user-invocable`   | Boolean.                                                                                                                                                |
| `tools`            | Minimal explicit list. Only the L4 orchestrator may include the `Agent` tool.                                                                           |
| `argument-hint`    | Required when `user-invocable: true`.                                                                                                                   |
| `color` (optional) | Distinct per agent for UI traceability.                                                                                                                 |

**H2 sections in this exact order:**

1. **Role** — opens with the literal sentence form "You are a **…**."; includes an in-scope / out-of-scope table.
2. **Requirements** — inputs the agent must receive.
3. **Dependencies** — five sub-tables (`MCP servers`, `Skills`, `Rules`, `Sibling agents`, `Output paths`) with trigger conditions per row.
4. **Operating Principles** — two-column table (`Principle | Rule`).
5. **Routing Map** — three-column table (`Trigger | Destination skill or sibling agent | Workflow step`).
6. **Workflow** — numbered steps; each declares inputs, actions, outputs.
7. **Output Rules** — bullet list; final bullet lists artefact paths.
8. **Boundaries** — bullets; every bullet starts with "You must NEVER".
9. **Quality Checks** — preamble "Before returning output, confirm:"; bullets are post-hoc verifiable.

**Forbidden in agent files:** example payloads, sample sentences, sample feature names, sample bash, sample JSON, narrative prose outside Role.

### 5.2 v0.1.0 agent roster

| #   | Agent                                           | Tier   | Layer | SDLC role                                          | MCP servers required (subset of §3.1)         | New plugin skills loaded                                                                                                                                                      | Rules consulted (subset of §6)                                    | Outputs (paths under `.claude/specs/<feature>/`)                                                                               |
| --- | ----------------------------------------------- | ------ | ----- | -------------------------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 0   | `claude-aws-architect-orchestrator-agent`       | v0.1.0 | L4    | Entry point + parallel fan-out + merge             | none directly (delegates)                     | `aws-sdlc-workflow`, `aws-spec-grounding`, `aws-mcp-routing`                                                                                                                  | `aws-spec-frontmatter`, `aws-docs`                                | `requirements.md`, `design.md`, `tasks.md` (final assembly)                                                                    |
| 1   | `claude-aws-architect-discovery-agent`          | v0.1.0 | L3    | Discovery + grounding ledger                       | `aws-knowledge`                               | `aws-spec-grounding`, `aws-grounding-cache`, `aws-mcp-routing`                                                                                                                | `aws-spec-frontmatter`, `aws-docs`                                | `requirements.md` (draft) + `.grounding-ledger.json` entries                                                                   |
| 2   | `claude-aws-architect-solution-architect-agent` | v0.1.0 | L3    | Solution architecture + design choice              | `aws-knowledge`, `aws-iac`                    | `aws-component-contract`, `aws-layered-diagram`, `aws-mcp-routing`, all 6 `aws-waf-*-skill` pillars                                                                           | `aws-cdk`, `aws-component-contract`, `aws-diagram`, `aws-docs`    | `design.md`, `contracts/<slug>.md` per component, `diagrams.d2` `c4-l1`/`c4-l2` layers, per-pillar review block in `design.md` |
| 3   | `claude-aws-architect-implementation-agent`     | v0.1.0 | L3    | Bundled IaC + cost ROM + IAM hygiene + test sketch | `aws-iac`, `aws-pricing`, `iam`, `cloudwatch` | `aws-component-contract`, `aws-mcp-routing`, `aws-waf-security-skill`, `aws-waf-cost-optimization-skill`, `aws-waf-reliability-skill`, `aws-waf-operational-excellence-skill` | `aws-cdk`, `aws-iam-policy`, `aws-component-contract`, `aws-test` | `contracts/<slug>.md` IaC + Cost + Security + Acceptance + Observability sections, `tasks.md`                                  |

Three additional v0.2 specialists (`cost-engineer`, `security-engineer`, `test-engineer`) split out of the bundled `implementation-agent` once the merge contract (§5.5) is validated under load.

### 5.3 L4 orchestrator extensions

Beyond §5.1, the orchestrator additionally declares:

- **Tools** must include `Agent`.
- **Frontmatter** must include `max-iterations` per O4 (default 3 at v0.1.0).
- **Routing Map** lists each L3 agent and the trigger keywords or conditions that select it (per §5.6).
- **Workflow** includes a step that emits parallel `Agent` calls in a single message and a step that merges results into the consolidated response per §5.5.
- **Quality Checks** include: every called specialist's output is represented in the merged response; failures are surfaced not dropped; the parallel-call cap from N13 is respected; the iteration cap from O4 is respected.

### 5.4 L3 agent dependency contract

Every L3 agent additionally declares in its **Dependencies** section:

- **Reads** — exact prior-artefact paths it consumes.
- **Writes** — exact artefact paths it produces.
- **Calls** — sibling agents it may invoke (typically empty for L3).
- **MCP tool budget** — maximum number of MCP tool calls per invocation before escalating back to the orchestrator.

### 5.5 Merge contract (orchestrator)

The orchestrator merges parallel L3 specialist outputs per the rules below.

**Conflict-resolution priority order** (high → low):

1. **Security correctness** — any specialist's security-blocking finding (IAM violation, exposed secret, public-access default, missing encryption) wins regardless of other specialists' designs.
2. **Factual correctness** — a specialist's grounded-by citation (per F4) wins over an un-grounded claim from another specialist.
3. **Cost ceiling** — if the user named a budget in the prompt, the cost-engineer's output (v0.2) constrains downstream choices.
4. **Convergence on architecture** — when specialists agree on a service or pattern, that's locked; further proposals are flagged.
5. **Recency** — when two specialists fetch the same fact at different times, the most recent grounded-by citation wins.

**Conflict-surfacing format:**

When specialists disagree on a non-trivial design choice (data store, async vs sync, region strategy), the orchestrator does **not** silently pick. The merged response includes a `## Open Questions` section listing each disagreement: which specialists, the competing options, the priority-rule outcome (or "raised to user" if no rule applies), and the citations or rationales on each side.

**Logging:**

Every conflict resolved by the priority rules is logged in the grounding ledger as a `conflict-resolution` entry with: timestamp, specialists involved, options, rule applied, chosen option. Conflicts raised to the user are logged as `unresolved`.

**Quality check:**

The orchestrator's Quality Checks (§5.1 H2.9) include: "every specialist disagreement appears either in `## Open Questions` or in the conflict-resolution log; none are silently dropped."

### 5.6 Escalation triggers (depth heuristic)

The orchestrator selects depth per these rules, evaluated in order:

1. **Explicit override**: user prompt contains `--deep` or `--quick` flags → use that depth, skip remaining rules.
2. **SDLC-artefact intent**: prompt names any of `design`, `architecture`, `IaC`, `CDK`, `threat model`, `cost estimate`, `security review`, `runbook`, `spec`, `requirements`, `contract`, `RFC`, `ADR` → full depth (parallel fan-out, all eligible specialists).
3. **Verb-of-creation**: prompt opens with `build`, `design`, `architect`, `propose`, `draft`, `spec`, `plan` and names an AWS service or noun → full depth.
4. **Verb-of-inquiry**: prompt opens with `what`, `how`, `which`, `is`, `does` → shallow depth (orchestrator answers from grounded knowledge; no fan-out unless follow-up matches rule 2 or 3).
5. **Default**: shallow.

Shallow → full escalation can also happen mid-turn if the orchestrator detects an SDLC-artefact intent in the user's clarification. Full → shallow downgrade does not happen automatically.

This heuristic is intentionally content-classified, not token-length-classified. ADR-A5 records the rationale.

---

## 6. Rules (file-scoped instructions)

### 6.1 Canonical rule declaration contract

Every rule file under `claude-aws-architect/rules/<name>.instructions.md` must declare:

**Frontmatter keys:**

| Key           | Constraint                                                             |
| ------------- | ---------------------------------------------------------------------- |
| `description` | Concise phrase (not a sentence).                                       |
| `applyTo`     | Glob; narrowest matching pattern; multiple globs allowed as YAML list. |
| `inclusion`   | One of `always`, `conditional`, `manual`.                              |

**Body:**

- 2–6 self-contained bullets, total ≤200 words.
- Each bullet states _what must hold_ in the matched file. No "how to write it" examples.
- May reference a sibling skill by name (`apply <skill-name>`).
- No code blocks, no example payloads, no sample identifiers.

### 6.2 Rule roster

| #   | Rule file                                | applyTo glob (declarative)                                                    | Mandate (declarative summary)                                                                                                                                                |
| --- | ---------------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `aws-cdk.instructions.md`                | CDK source roots: stack files, construct libs, `cdk.json`, `cdk.context.json` | Construct naming · stack-boundary cohesion · prop-interface immutability · cross-stack reference safety · removal-policy defaults · environment binding · no inline IAM JSON |
| 2   | `aws-iam-policy.instructions.md`         | IAM policy JSON files anywhere in repo                                        | Least-privilege bar · no wildcard actions outside read-only · condition-key requirements · resource ARN scoping · deny-list hygiene · no wildcard principals                 |
| 3   | `aws-sdk-usage.instructions.md`          | TS/Python source files importing the AWS SDK                                  | Client construction · retry/back-off discipline · pagination · credential providers · region resolution · async error narrowing · no client instantiation in hot paths       |
| 4   | `aws-bedrock-prompt.instructions.md`     | Prompt and AgentCore artefact paths                                           | Prompt structure · guardrail binding · model-id pinning · response-shape contract · tool-use schema · evaluation-hook presence · no secrets in prompts                       |
| 5   | `aws-test.instructions.md`               | AWS-touching `*.test.ts` and `*.spec.ts` paths                                | LocalStack-vs-real-AWS bar · fixture isolation · no real network in unit tests · contract-test mandate for cross-account flows · deterministic seeds                         |
| 6   | `aws-docs.instructions.md`               | Plugin docs and consumer specs                                                | Audience-first headings · mandatory C4 reference per `design.md` · cite-coverage on every assertion · no broken cross-links · no marketing language                          |
| 7   | `aws-diagram.instructions.md`            | Every `*.d2` file                                                             | Layer-tag taxonomy (§9.6) · node naming · edge-label discipline · sequence-swimlane rules · no orphan nodes · no untagged top-level shapes                                   |
| 8   | `aws-component-contract.instructions.md` | Component contracts under `.claude/specs/**/contracts/*.md`                   | Required frontmatter (§9.4) · section ordering · integration-link validity · observability triple (metric/log/trace) · grounded-by present                                   |
| 9   | `aws-spec-frontmatter.instructions.md`   | Spec docs under `.claude/specs/**/{requirements,design,tasks}.md`             | Required frontmatter (§9.3) · grounded-by minimum count · status-transition discipline · cross-doc consistency                                                               |

---

## 7. Hooks and quality-or-security scripts

### 7.1 Hook entry contract (`hooks/hooks.json`)

Every entry declares: `name`, `event` (Claude Code hook event), `matcher`, optional `filePattern` (glob), `command` (must reference `${CLAUDE_PLUGIN_ROOT}`), `enabledByDefault` (boolean), optional `enabledWhen` boolean expression over consumer settings.

### 7.2 Hook script roster (declarative)

| #   | Hook script                      | Event       | Matcher / file scope                              | Mandate (declarative)                                                                                               | Default-enabled |
| --- | -------------------------------- | ----------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | :-------------: |
| 1   | `dispatch.sh`                    | host-side   | n/a (entry point)                                 | Read consumer settings, resolve matching `hooks.json` entries, invoke each in declared order, aggregate exit codes. |       yes       |
| 2   | `aws-api-write-guard.sh`         | PreToolUse  | AWS-API MCP write-call tool                       | Detect AWS write verbs; require explicit confirmation when not in read-only mode; block if confirmation absent.     |       yes       |
| 3   | `aws-secret-scanner.sh`          | PreToolUse  | All file write/edit tools                         | Scan diff for credentials, tokens, AWS keys, private keys; **block** the write on hit; emit redacted finding.       |       yes       |
| 4   | `aws-on-cdk-write.sh`            | PostToolUse | Writes/edits inside CDK source roots              | Surface CDK-synth-and-Nag-check nudge in response stream; never run synth automatically.                            |       no        |
| 5   | `aws-on-iam-write.sh`            | PostToolUse | Writes/edits to IAM JSON                          | Validate JSON; run least-privilege heuristic via `iam` MCP; surface findings; never auto-edit.                      |       no        |
| 6   | `aws-on-bedrock-prompt-write.sh` | PostToolUse | Writes/edits to prompt or AgentCore artefacts     | Check guardrail-binding, model-id pinning, evaluation-hook presence; surface missing fields.                        |       no        |
| 7   | `aws-test-coverage.sh`           | PostToolUse | Writes/edits to AWS-touching implementation files | Surface matching `*.spec.ts` and `*.test.ts` paths; flag missing tests; flag stale tests by mtime delta.            |       no        |

### 7.3 Common hook script contract

Every hook script must declare in a header comment block:

- Inputs read from stdin (Claude Code hook payload).
- Outputs: stdout (advisory), stderr (block reason).
- Exit codes: `0` allow · `1` block · `2` advisory non-blocking finding.
- Side-effect scope: limited to the consumer project root.
- Forbidden: hardcoded secrets, `eval`, unbounded recursion, network calls outside the AWS CLI/MCP path.
- Required: `set -euo pipefail`, `IFS=$'\n\t'`, double-quoted variable references, `trap 'rm -rf "$tmpdir"' EXIT INT TERM` for any tempfile-using script, `mktemp -t "claude-aws-architect.XXXXXX"` for tempfiles, `shellcheck`-clean.

---

## 8. Setup scripts

### 8.1 Script roster

| Script         | Required behaviour (declarative)                                                                                                                                                                                                                    | Exit codes                                                                                        |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `init.sh`      | Detect/install `uvx` (and underlying `uv`), `jq`, `d2`, `shellcheck`. Verify `aws` CLI present. Pre-fetch every stdio MCP package declared in `.mcp.json`. Write consumer settings template if absent (or with `--force`). Exec `doctor.sh` at end. | Inherits from `doctor.sh`.                                                                        |
| `doctor.sh`    | Verify `uvx`, `aws` CLI, env (`AWS_PROFILE`, `AWS_REGION`), MCP package resolution per server, `sts:GetCallerIdentity`, minimum-IAM presence (N12). `--json` flag emits structured output.                                                          | `0` OK · `1` missing tool · `2` missing env · `3` MCP unresolved · `4` STS · `5` IAM insufficient |
| `install.sh`   | Two modes: `--symlink` (default — symlinks plugin into consumer's `.claude/plugins/claude-aws-architect/`) and `--copy` (copies templates into `.claude/`). Idempotent. Never overwrite existing consumer files. Log every action.                  | `0` OK · `64` bad arg · `65` target conflict                                                      |
| `uninstall.sh` | Reverse `install.sh`. Never delete `.claude/specs/`, `.claude/steering/`, or consumer-authored hooks. `--dry-run` flag prints actions without performing them.                                                                                      | `0` OK · `64` bad arg                                                                             |

### 8.2 Cross-script invariants

- `set -euo pipefail`, `IFS=$'\n\t'`, double-quoted variable expansion, `shellcheck`-clean.
- Honour `--help` (prints declared usage and exits 0).
- Honour `$NO_COLOR` and write structured logs to stderr.
- Never write outside `claude-aws-architect/` or the consumer's `.claude/` tree.
- Use `mktemp -t "claude-aws-architect.XXXXXX"` for any tempfile; install `trap 'rm -rf "$tmpdir"' EXIT INT TERM` immediately after.
- Cross-platform: `bash` (not `sh`); avoid GNU-isms or feature-detect them; tested on macOS bash 3.2 and Ubuntu bash 5+.

---

## 9. Canonical schemas

### 9.1 `powers/<name>.power.json`

Required keys: `name` (matches filename without `.power.json`), `version` (SemVer), `description` (one sentence), `mcpServers` (array, ≥1, names match `.mcp.json`), `skills` (array, names exist under `skills/`), `hooks` (array, names exist in `hooks/hooks.json`), `commands` (array, names exist under `commands/`).

### 9.2 `hooks/hooks.json` entry

Required keys: `name`, `event`, `matcher`, optional `filePattern`, `command` (must reference `${CLAUDE_PLUGIN_ROOT}`), `enabledByDefault`, optional `enabledWhen`.

### 9.3 Spec-doc frontmatter

Required keys: `feature` (slug), `created`, `updated`, `status` (`draft | review | accepted | implemented`), `grounded-by` (array of `<server>:<short-key>`; ≥1 on `requirements.md`).

### 9.4 Component-contract frontmatter

Required keys: `component` (slug), `kind`, `version`, `status`, `talks-to` (array of sibling slugs), `grounded-by` (array, ≥1).

Body sections in this exact order: _Purpose · Interface (Inputs / Outputs / Errors) · Sequence · Component view (C4 L3) · Acceptance criteria · Observability (metric / log / trace) · Integration points._

### 9.5 Grounded-by citation

Reference form: `<mcp-server>:<short-key>`. Short-key derivation per N15 + N16: first 8 hex chars of SHA-1 of canonicalised query; on collision, extend to 12 hex for the colliding entry only. Full payload entry in `.grounding-ledger.json` declares: `server`, `tool`, `query`, `retrieved` (ISO-8601), `result_summary`, `ttl-class` (one of `pricing | quota | api-shape | region | immutable`).

### 9.6 `diagrams.d2` layer tags

Required tags: `c4-l1`, `c4-l2`, `c4-l3-<container>` (one per L2 container), `seq-system`, `seq-component`, `seq-error`. No untagged top-level nodes.

---

## 10. Transcript-replay test harness

### 10.1 Purpose

Convert every runtime claim in the spec (specifically gates 8, 9, 11, 12 in §11) into a deterministic CI assertion. Without this, "the orchestrator fans out in parallel" and "every component has a contract" are wishes, not gates.

### 10.2 Fixture format

Each fixture lives under `tests/transcripts/<name>/` and contains:

- `prompt.txt` — the canonical user prompt, frozen.
- `expected-tools.jsonl` — one JSON line per expected tool call, ordered: `{step, tool, server?, fan_out_index?}`.
- `expected-artefacts.txt` — list of file paths the run must produce under `.claude/specs/<feature>/`.
- `expected-merge.json` — for fan-out fixtures: which specialists must appear in the merged output, expected `## Open Questions` keys (if any), expected priority-rule applications (per §5.5).

### 10.3 v0.1.0 fixture set (minimum)

| Fixture           | Validates                                                                                                                                                 |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vibe-shallow`    | §5.6 rule 4 (verb-of-inquiry → shallow); no fan-out; no artefacts written.                                                                                |
| `sdlc-full-depth` | §5.6 rule 2 (SDLC-artefact intent → full depth); ≥2 parallel `Agent` calls; F5 + F6 artefacts produced.                                                   |
| `merge-conflict`  | §5.5 priority rules: planted disagreement between solution-architect and implementation; verifies the resolved-vs-raised outcome.                         |
| `degraded-mcp`    | §3.5: simulated `aws-knowledge` 5xx; verifies `grounding-deferred` marker in output and ledger entry.                                                     |
| `secret-in-diff`  | §7.2 hook 3: planted AWS access key in a write; verifies block + redacted finding.                                                                        |
| `iteration-cap`   | O4: prompt designed to keep specialists disagreeing; orchestrator must halt at the iteration cap with `iteration-cap-reached` marker rather than looping. |

### 10.4 Runner

`tests/run-transcripts.sh` executes each fixture, captures the tool-call trace, asserts against `expected-*` files, and exits non-zero on first mismatch. Runs in CI on every PR. Snapshot updates require explicit `--update-snapshots` and a reviewer comment.

---

## 11. Verification gates

Gates split into **deterministic** (runnable locally and in CI without a live model) and **runtime** (requires the transcript-replay harness from §10).

### 11.A Deterministic gates

1. `doctor.sh` exits 0.
2. `plugin.json` parses; `name` field present; `engines.claude-code` field present per O1.
3. No absolute paths anywhere in `claude-aws-architect/`.
4. `shellcheck` clean across every bash script.
5. Every Markdown with `---` frontmatter parses as YAML.
6. Every `powers/*.power.json` matches §9.1.
7. Every `hooks/hooks.json` entry matches §9.2.
8. Every rule file under `rules/` matches §6.1 (frontmatter + 2–6 bullets, ≤200 words, no example code).
9. Every agent file under `agents/` matches §5.1 (frontmatter + H2 ordering + section constraints).
10. Every new skill under `skills/` matches §4.3 (frontmatter + section ordering including the **required Gotchas section** + no example bodies).
11. Every hook script matches §7.3 (header comment + exit codes + side-effect scope + bash-safety boilerplate).
12. `.mcp.json` lists every server in §3.1 and no others (v0.2 servers gated behind explicit version bump); every entry carries a pinned `version` per §16.2 and a `timeoutMs` per O2.
13. Re-running `init.sh` is idempotent (no errors, no duplicate writes); asserted against a tempdir snapshot diff.
14. `markdownlint-cli2 --config .markdownlint.jsonc` and `prettier --check` pass on every Markdown file.
15. `README.md` contains a top-level `## Trademark notice` section with the four declarative bullets specified in §15.4 (asserted by a CI grep-and-count check).
16. **Skill description quality**: every `skills/*/SKILL.md` frontmatter `description` field matches the §4.3 requirements _and_ contains ≥3 distinct trigger keywords drawn from `trigger-keywords.txt` (a per-skill sibling file declaring the skill's own keyword set), is ≤300 chars, and does not begin with the prefix `This skill` or `A skill that`. Asserted by a CI parser against `trigger-keywords.txt`.
17. **SKILL.md size budget**: every `skills/*/SKILL.md` body (excluding frontmatter) is ≤500 lines per Anthropic authoring guidance. Skills exceeding the budget must split content into `references/<topic>.md` files. Asserted by `wc -l`.
18. **Tool-name length budget**: the longest fully-qualified tool name across all `.mcp.json` servers — computed as `len("mcp__plugin_<plugin>_<server>__<longest-tool>")` — is < 64 characters per O3. Asserted by a CI script that resolves each server's tool list (statically declared in `.mcp.json#tools[]` for stdio servers, fetched once at CI time for HTTP servers and cached).

### 11.B Runtime gates (transcript-replay)

19. `tests/run-transcripts.sh` exits 0 across every fixture in §10.3.
20. Fixture `sdlc-full-depth` asserts ≥2 specialist `Agent` calls observable in a single orchestrator turn (replaces v1 gate 9).
21. Fixture `sdlc-full-depth` asserts every artefact path required by F5 and F6 is produced.
22. Fixture `sdlc-full-depth` asserts every `requirements.md` acceptance criterion has ≥1 `grounded-by` entry per F4.
23. Fixture `sdlc-full-depth` asserts every component named in `design.md` has a matching `contracts/<slug>.md`.
24. Fixture `sdlc-full-depth` asserts `diagrams.d2` contains every required layer tag from §9.6.
25. Fixture `merge-conflict` asserts §5.5 priority rules are applied as declared.
26. Fixture `degraded-mcp` asserts §3.5 fallback labels appear in output.
27. Fixture `iteration-cap` asserts the orchestrator halts at the O4 cap with an `iteration-cap-reached` marker rather than looping.

### 11.C Cross-platform gates (CI matrix)

28. Every gate in §11.A passes on `ubuntu-latest`.
29. Every gate in §11.A passes on `macos-latest`.

### 11.D Install-safety gates (CI fixtures)

30. `install.sh --symlink` on a clean tree → `uninstall.sh` → tree state byte-identical to pre-install (asserted against a tar snapshot).
31. `install.sh --symlink` on a dirty tree containing pre-existing `.claude/specs/`, `.claude/steering/`, `.claude/hooks/` with consumer-authored content → `uninstall.sh` → all consumer-authored content present, byte-identical (asserted against a tar snapshot of the dirty subset).
32. `install.sh --symlink` followed by a second `install.sh --symlink` (re-install): no errors, no duplicate writes, no lock contention. Idempotency assertion.
33. `install.sh --copy` followed by `uninstall.sh --dry-run`: dry-run output enumerates exactly the files `uninstall.sh` (no `--dry-run`) would remove; asserted by diffing the two action lists.

### 11.E Release gate

34. The dogfood meta-spec under `.claude/specs/claude-aws-architect/` (per §H1) is generated by running the plugin's own `/aws` command against the plugin's own design intent prompt (§13.G); the resulting `requirements.md`, `design.md`, `tasks.md`, `contracts/*.md`, and `diagrams.d2` pass every gate in §11.A and §11.B. This is a release blocker for v0.1.0: the plugin must successfully design itself before tagging.

---

## 12. Execution sequence (PR-sized commits, branch `feat/aws-mcp-plugin`)

Each numbered item is intended to land as a single PR ≤500 net lines of change. Commits within a PR are author's choice.

### 12.A Foundation (sequential)

1. `feat(plugin): scaffold manifest, MCP wiring (6 servers v0.1.0), README, SPEC, CHANGELOG`.
2. `feat(plugin): add deterministic gates 1–18 in CI (lint, schema, frontmatter, trademark notice, description quality, line budget, tool-name budget)`.
3. `feat(plugin): add transcript-replay harness skeleton + first fixture (vibe-shallow)`.

### 12.B Workflow skills (parallelisable PRs)

4. `feat(plugin): add aws-mcp-routing skill`.
5. `feat(plugin): add aws-spec-grounding skill`.
6. `feat(plugin): add aws-grounding-cache skill`.
7. `feat(plugin): add aws-component-contract skill`.
8. `feat(plugin): add aws-layered-diagram skill`.
9. `feat(plugin): add aws-sdlc-workflow skill`.

### 12.B-2 WAF pillar skills (parallelisable PRs, can run alongside 12.C)

10. `feat(plugin): add aws-waf-operational-excellence-skill`.
11. `feat(plugin): add aws-waf-security-skill`.
12. `feat(plugin): add aws-waf-reliability-skill`.
13. `feat(plugin): add aws-waf-performance-efficiency-skill`.
14. `feat(plugin): add aws-waf-cost-optimization-skill`.
15. `feat(plugin): add aws-waf-sustainability-skill`.

### 12.C Agents (sequential — each unblocks the next)

16. `feat(plugin): add claude-aws-architect-orchestrator-agent (L4, scaffold only — no fan-out yet)`.
17. `feat(plugin): add claude-aws-architect-discovery-agent (L3) + transcript fixture`.
18. `feat(plugin): wire orchestrator → discovery delegation; pass first end-to-end fixture`.
19. `feat(plugin): add claude-aws-architect-solution-architect-agent (L3) + parallel fan-out (2 agents) + merge contract from §5.5; depends on all 6 WAF pillar skills`.
20. `feat(plugin): add merge-conflict + degraded-mcp + iteration-cap transcript fixtures; pass runtime gates 19–27`.
21. `feat(plugin): add claude-aws-architect-implementation-agent (L3); fan-out at N=3; depends on 4 WAF pillar skills (security, cost, reliability, OE)`.

### 12.D Rules (parallelisable, can ship anytime after 12.A)

22. `feat(plugin): add 9 rules under rules/`.

### 12.E Commands (sequential, after agents)

23. `feat(plugin): add 3 commands (/aws, /aws-spec, /aws-doctor)`.

### 12.F Powers, hooks, scripts (parallelisable)

24. `feat(plugin): add 3 Powers (cdk, cost, security)`.
25. `feat(plugin): add hooks registry, hook dispatcher, secret-scanner, aws-api-write-guard`.
26. `feat(plugin): add 4 secondary hook scripts (cdk-write, iam-write, bedrock-prompt-write, test-coverage)`.
27. `feat(plugin): add init, doctor, install, uninstall scripts; pass install-safety gates 30–33`.
28. `feat(plugin): add CI matrix (ubuntu + macos); pass gates 28–29`.

### 12.F-2 Security and release infrastructure (parallelisable)

28a. `feat(plugin): add SECURITY.md, threat-model.md (§16.3), Dependabot config for Actions, MCP version-skew check workflow (§16.4)`.
28b. `feat(plugin): add SUPPORT.md, GitHub issue templates, PR template (§17.2, §17.3)`.

### 12.G Templates and dogfood

29. `feat(plugin): add templates (specs, contracts, diagrams)`.
30. `chore(repo): self-dogfood — generate claude-aws-architect/templates/examples/<feature>/ from §10.3 sdlc-full-depth fixture; commit as canonical reference (§H5)`.
31. `chore(repo): release dogfood — run /aws against the plugin's own design intent prompt (§13.G); generate .claude/specs/claude-aws-architect/ meta-spec; verify it passes every §11.A and §11.B gate (release gate 34)`.

### 12.H ADRs (separate PR)

32. `docs(adr): A1 architecture, A2 component-contracts, A3 MCP-server-roster, A4 merge-contract, A5 escalation-heuristic, A6 license-and-distribution, A7 supply-chain-and-release` _(separate PR, branch `docs/adr-aws-plugin`)_.

---

## 13. Substrate authoring backlog

This section enumerates every skill the v0.1.0 orchestrator + agents reference, mapped to authoring status. No agent declares a dependency on a skill not in this table.

#### Workflow skills

| Skill                    | Authored under                                        | Authoring tier | Used by                                                     |
| ------------------------ | ----------------------------------------------------- | -------------- | ----------------------------------------------------------- |
| `aws-sdlc-workflow`      | `claude-aws-architect/skills/aws-sdlc-workflow/`      | v0.1.0         | orchestrator                                                |
| `aws-spec-grounding`     | `claude-aws-architect/skills/aws-spec-grounding/`     | v0.1.0         | orchestrator, discovery, solution-architect, implementation |
| `aws-grounding-cache`    | `claude-aws-architect/skills/aws-grounding-cache/`    | v0.1.0         | aws-spec-grounding (transitive)                             |
| `aws-component-contract` | `claude-aws-architect/skills/aws-component-contract/` | v0.1.0         | solution-architect, implementation                          |
| `aws-layered-diagram`    | `claude-aws-architect/skills/aws-layered-diagram/`    | v0.1.0         | solution-architect                                          |
| `aws-mcp-routing`        | `claude-aws-architect/skills/aws-mcp-routing/`        | v0.1.0         | all agents                                                  |

#### WAF pillar skills

| Skill                                  | Authored under                                                      | Authoring tier | Used by                            |
| -------------------------------------- | ------------------------------------------------------------------- | -------------- | ---------------------------------- |
| `aws-waf-operational-excellence-skill` | `claude-aws-architect/skills/aws-waf-operational-excellence-skill/` | v0.1.0         | solution-architect, implementation |
| `aws-waf-security-skill`               | `claude-aws-architect/skills/aws-waf-security-skill/`               | v0.1.0         | solution-architect, implementation |
| `aws-waf-reliability-skill`            | `claude-aws-architect/skills/aws-waf-reliability-skill/`            | v0.1.0         | solution-architect, implementation |
| `aws-waf-performance-efficiency-skill` | `claude-aws-architect/skills/aws-waf-performance-efficiency-skill/` | v0.1.0         | solution-architect                 |
| `aws-waf-cost-optimization-skill`      | `claude-aws-architect/skills/aws-waf-cost-optimization-skill/`      | v0.1.0         | solution-architect, implementation |
| `aws-waf-sustainability-skill`         | `claude-aws-architect/skills/aws-waf-sustainability-skill/`         | v0.1.0         | solution-architect                 |

#### v0.2 deferred

| Skill                 | Authored under                                     | Authoring tier | Used by                     |
| --------------------- | -------------------------------------------------- | -------------- | --------------------------- |
| `aws-hook-authoring`  | `claude-aws-architect/skills/aws-hook-authoring/`  | v0.2           | plugin-author workflow only |
| `aws-power-authoring` | `claude-aws-architect/skills/aws-power-authoring/` | v0.2           | plugin-author workflow only |

**Skills explicitly NOT authored at v0.1.0** (and not referenced by any v0.1.0 agent):

- IAM-specialist skill, cost-estimator skill, IaC skill, diagram-styling skill, AgentCore knowledge skill, OWASP scanner skill, TypeScript skills, markdown-authoring skill, gap-audit skill, devils-advocate skill, plan-md-schema skill, etc. — every one of these is replaced at v0.1.0 by the rule files in §6 plus the MCP servers in §3.1 plus the relevant WAF pillar skill where applicable. Agents call MCPs directly for AWS knowledge rather than going through skill indirection.
- `aws-bedrock-validation` — deferred to v0.2 with the Bedrock Power.

This is the substrate-iceberg control: the orchestrator can only declare dependencies on skills in this table. Anything else is an authoring backlog item, gated by §S2.

#### 13.G Release dogfood — design intent prompt

Per §11.E gate 34, v0.1.0 cannot tag until the plugin successfully designs itself. The release-dogfood prompt is fixed declaratively below; it runs against `/aws` in the plugin's own repository (which has §H1 in place) and produces `.claude/specs/claude-aws-architect/`.

**Required prompt content** (declarative; the build phase composes the literal):

- States that the user wants a Claude Code plugin for AWS Well-Architected SDLC.
- Names the plugin's own scope: greenfield single plugin, MIT licensed, MCP servers, L4 orchestrator, L3 specialists, parallel fan-out, grounded citations.
- Asks for `requirements.md`, `design.md`, `tasks.md`, per-component contracts, and `diagrams.d2`.
- Uses `--deep` to force full-depth escalation per §5.6 rule 1.

**Acceptance:**

- The generated meta-spec passes every gate in §11.A and §11.B.
- The meta-spec's `design.md` names every L3 specialist defined in §5.2.
- The meta-spec's `contracts/` directory includes one contract per L3 specialist plus the orchestrator.
- The meta-spec's `diagrams.d2` carries every layer tag in §9.6.
- The meta-spec's `.grounding-ledger.json` contains ≥1 citation against `aws-knowledge` MCP.

**Failure handling:** if the plugin cannot design itself, v0.1.0 does not tag. The failure mode (which gate failed, which artefact is missing) is documented in the issue tracker, fixed, and re-attempted. The dogfood is a release blocker by design — a plugin that can't design itself isn't ready to design anyone else's systems.

---

## 14. Quick start (declarative procedure)

1. From the consuming project root, run `install.sh --symlink`, then `init.sh` with the consumer's AWS profile and region as flags.
2. Issue a smoke prompt to the `/aws` command. The prompt is chosen by the user at run time; no canonical example feature is fixed in this plan, but §10.3's `sdlc-full-depth` fixture is recommended for verification.
3. Confirm the artefacts in F5 and F6 appear under `.claude/specs/<feature>/` plus a git-ignored grounding ledger.
4. Render the diagrams file with the D2 CLI to produce SVG output.
5. Run the spec validator (`/aws-spec <feature> --validate`); every gate in §11.A and §11.B must pass.
6. Capture the produced folder into `claude-aws-architect/templates/examples/<feature>/` as a canonical reference artefact (§H5).

---

## 15. Licensing, telemetry, listing, and trademark posture

### 15.1 License

The plugin ships under the **MIT License**. A `LICENSE` file is committed to the repository root before the v0.1.0 tag.

- Permissive: anyone may use, modify, redistribute, and embed in proprietary work.
- Standard for the Claude Code plugin ecosystem (matches the de-facto convention used by comparable AWS-tooling plugins).
- No contributor licence agreement at v0.1.0; contributions are accepted under the inbound = outbound principle.

### 15.2 Telemetry

The plugin ships with **no telemetry, ever** at v0.1.0.

- Zero data is collected, logged, or transmitted by the plugin or any of its agents, hooks, or scripts.
- The grounding ledger (§9.5) is a local file under `.claude/specs/<feature>/.grounding-ledger.json`, git-ignored, and never read or transmitted by the plugin itself.
- `doctor.sh --json` emits structured output to stdout for the user's own diagnostic use; it makes no network calls beyond the AWS endpoints required for `sts:GetCallerIdentity`.
- The README states this explicitly under a `## Privacy` section so users do not have to infer it.

This decision is revisited only if external user demand surfaces a compelling case; even then, any future telemetry is opt-in, local-only by default, and never transmits without explicit user consent.

### 15.3 Marketplace listing strategy

The plugin's listing posture is **delayed and curated**:

- **v0.1.0 release**: GitHub-only. Discovery limited to the repository README, GitHub topic tags (`aws`, `claude-code`, `claude-plugin`, `aws-cdk`, `claude-skills`), and word-of-mouth.
- **After v0.1.1** (i.e. after the first round of real-user bugfixes): submit listings to two community indexes — `skills.sh` (the Vercel-hosted skills leaderboard) and `awesome-claude-skills` (community-curated index). One submission each, tracked in CHANGELOG.
- **Not listed at any tier**: npm (Claude Code plugins are not npm packages), commercial marketplaces (no commercial offering), and ad-hoc awesome-\* repos beyond the two named.
- **Each listing carries**: a short description matching `plugin.json#description`, a screenshot of the dogfooded `sdlc-full-depth` example, and the `claude-aws-architect` install command.

### 15.4 Trademark disclaimer

The README includes a `## Trademark notice` section with the following declarative content (no example body here; the build phase fills it from this template):

- A statement that the plugin is **not affiliated with, endorsed by, or sponsored by Amazon Web Services, Inc. or its affiliates**.
- An acknowledgement that "AWS", "Amazon Web Services", "Well-Architected", and the AWS service names referenced throughout the plugin are trademarks of Amazon.com, Inc. or its affiliates.
- A pointer to the AWS trademark guidelines URL.
- A statement that "AWS" appears in the plugin name (`claude-aws-architect`) as a descriptive token denoting the cloud provider the plugin targets, not as a claim of affiliation or endorsement.

This section is enforced by §11.A gate 15: a CI check ensures the four bullet points above are present in `README.md` under a top-level `## Trademark notice` heading.

### 15.5 Future-tier promotions

Items in this section are only revisited when the conditions in §S2 (transcript-replay green for 30 days + ≥1 external user installation) are satisfied:

- License: stays MIT unless a corporate sponsor requires Apache 2.0; in that case bump alongside a CLA decision.
- Telemetry: opt-in local-only mode could be added in v0.2+ if filing-issues workflow benefits from log capture; opt-in remote telemetry remains out of scope indefinitely.
- Listing: additional indexes considered only if the two v0.1.1 listings drive measurable installs over a 60-day window.

---

## 16. Security and supply chain

### 16.1 Security disclosure

The repository ships a `SECURITY.md` at root declaring:

- Vulnerability disclosure email or GitHub Security Advisory channel — declarative; the build phase fills in the literal once the project owner registers a contact address.
- Response window: best-effort acknowledgement within 7 days; no SLA on fixes for v0.1.x.
- In-scope: hook scripts under `hooks/scripts/`, install/uninstall scripts under `scripts/`, `.mcp.json` server configuration, agent and skill files that influence Claude's tool-call behaviour.
- Out-of-scope: vulnerabilities in upstream MCP servers (report to AWS Labs directly), vulnerabilities in Claude Code itself (report to Anthropic), vulnerabilities in user-authored content under `.claude/specs/`.

### 16.2 Supply-chain integrity

- **MCP server version pins**: every entry in `.mcp.json` carries an explicit `version` field. `uvx`-resolved targets pin to a specific package version (e.g. `awslabs.aws-knowledge-mcp-server==X.Y.Z`); HTTP servers pin to the documented stable URL with a `versionCheck` script that fails CI if the upstream version skews. v0.1.0 deterministic gate 12 enforces presence of `version` on every server.
- **GitHub Actions pinning**: every workflow under `.github/workflows/` pins each `uses:` reference to a full commit SHA, not a tag. Renovate-bot or Dependabot for Actions surfaces SHA updates as PRs.
- **No npm dependencies in v0.1.0**: per N2, the plugin is markdown + JSON + bash. No `package.json`. The only externally-fetched code is via `uvx` (which is itself version-pinned in §16.2) and the AWS CLI (assumed pre-installed by the user, verified by `doctor.sh`).
- **No code signing for v0.1.0**: signed commits and signed releases are deferred. v0.1.0 ships unsigned. ADR-A6 records this trade-off.

### 16.3 Threat model summary

The plugin's threat model is documented in `docs/threat-model.md`. v0.1.0 enumerates four threat classes:

- **Prompt injection via MCP server output**: a malicious or compromised MCP server returns text designed to override the orchestrator's instructions. Mitigation: §6 file-scoped rules constrain agent behaviour regardless of MCP output; §5.5 merge contract surfaces unexpected agent behaviour as Open Questions; the user reviews every Claude Code action before it executes.
- **Hook script abuse**: a malicious user authoring spec content tries to trigger a hook script with crafted file paths. Mitigation: §7.3 constrains hook scope to consumer project root; `set -euo pipefail` and quoted variables prevent classic shell injection.
- **Install-time tampering**: a forked install script writes outside its declared scope. Mitigation: §11.D gates assert byte-identical state before/after on dirty trees; CI runs the install fixtures.
- **Secret exfiltration via grounding ledger**: the ledger could record API responses containing secrets. Mitigation: `aws-grounding-cache` skill (§4.2) requires secret-redaction on insert; gate 17 (SKILL.md line budget) keeps skill instructions short enough to prevent silent erosion of the redaction rule.

### 16.4 Dependency monitoring

- Renovate (or Dependabot) configured for: GitHub Actions only at v0.1.0.
- MCP server version-skew check: the `versionCheck` script in §16.2 runs nightly via a scheduled GitHub Actions workflow; opens an issue when an upstream MCP package version moves.

---

## 17. Release and support model

### 17.1 Release process

- Releases are tagged on `main` after gate 34 (release dogfood) passes.
- SemVer per N9. Pre-1.0 minor versions may break public spec interfaces; the CHANGELOG calls out every break.
- Each tagged release has a corresponding GitHub Release with: the CHANGELOG entry copied into the release notes, a `tar.gz` of the plugin tree, and a SHA-256 checksum file. The release page is the canonical install source.
- Hotfixes for v0.1.x security issues land on a `release/0.1.x` branch when v0.2 is in development; otherwise on `main`.
- One supported version at a time at v0.1.x. No backports unless the active version is v1.0+.

### 17.2 Issue and PR templates

The repository ships under `.github/`:

- `ISSUE_TEMPLATE/bug_report.md` — declarative; required fields: plugin version, Claude Code version (per O1), OS, MCP server roster from `doctor.sh --json`, repro steps, expected vs actual behaviour.
- `ISSUE_TEMPLATE/feature_request.md` — declarative; required fields: use case, current workaround, proposed scope tier (v0.2 / v1.0).
- `ISSUE_TEMPLATE/security.md` — points to `SECURITY.md` and asks the reporter not to file in the public tracker.
- `pull_request_template.md` — declarative; required: link to issue, gate-pass checklist (which §11 gates the PR exercises), CHANGELOG entry, scope-tier confirmation.

### 17.3 Support posture

`SUPPORT.md` declares:

- Support is best-effort, community-driven, no SLA.
- The supported version is the latest tagged release.
- Bug reports go to GitHub Issues with the bug template.
- Feature requests are triaged into v0.2, v1.0, or `wontfix` labels; `wontfix` carries a one-line rationale.
- Discussion-format questions go to GitHub Discussions (enabled at v0.1.0).

### 17.4 Versioning compatibility

- `plugin.json#version` follows SemVer per N9.
- `plugin.json#engines.claude-code` per O1 — bumping this minor or major requires a CHANGELOG entry under "BREAKING".
- `.mcp.json` server pins are version-bumped as a separate PR with the rationale in the commit body. Bumping a pinned MCP server is a `feat(deps)` commit, not `chore`.

---

## 18. Explicitly out of scope

This section records decisions made during v3 → v4 review to prevent re-litigation in future revisions. Each item below was considered and rejected for v0.1.0 with a recorded rationale.

- **Custom plugin telemetry / structured logging beyond the grounding ledger** — Claude Code already exposes every tool call and agent transition in the chat transcript. Duplicating that surface in plugin-owned log files adds maintenance burden without user benefit. Reconsidered only if a specific debugging gap surfaces.
- **Documentation site (mkdocs / Docusaurus / Astro Starlight)** — README + SPEC.md + dogfooded examples cover the v0.1.0 audience. A doc site is a marketing decision, not a quality bar.
- **Latency budgets (p50/p95/p99)** — the plugin does not control end-to-end latency; the model, network, and MCP servers do. Budgets are unenforceable without a control surface.
- **Standalone error catalogue (`docs/errors.md`)** — per O6, the §5.5 Open Questions section is the user-facing error surface. A separate catalogue duplicates content already produced by the orchestrator at runtime.
- **Internationalisation of plugin outputs** — plugin outputs are Claude's outputs; Claude handles language. The plugin's own files (README, SPEC, skill descriptions) ship in English at v0.1.0; translations are a community contribution surface, not a v0.1.0 deliverable.
- **Code signing for commits and releases** — overkill for a community plugin. Reconsidered only if the plugin reaches an audience where signature verification becomes a real requirement.
- **CodeQL / SAST** — the plugin is markdown + JSON + bash. CodeQL adds no signal here; `shellcheck` (already in §11.A gate 4) is the right tool.
- **Performance regression tests** — see latency budgets above.
- **Comparison / positioning section ("vs. Q Developer," "vs. zxkane/aws-skills")** — README marketing content, drafted at v0.1.1 listing time, not a v0.1.0 spec section.
- **Repo polish items** (logo, badges, `.editorconfig`, `CODE_OF_CONDUCT.md`, cspell, codecov, lychee link checker) — tracked in a non-spec backlog file `docs/repo-polish-checklist.md`. None require spec changes.
