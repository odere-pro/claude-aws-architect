# Changelog

All notable changes to `claude-aws-architect` are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

One entry per merged PR. The plugin starts at `v0.1.0`; until that tag ships (gated by [PR-PLAN.md](./docs/plan/PR-PLAN.md) PR 31), entries accumulate under `[Unreleased]` and are promoted on tag.

## [Unreleased]

### Added

#### Planning and scaffold

- **PR 0** — Planning import: `docs/plan/SPEC-v4.md`, `docs/plan/PR-PLAN.md`, `docs/plan/PR-CONVENTIONS.md`.
- **PR 1** — Plugin scaffold: `.claude-plugin/plugin.json`, `.mcp.json` (6 AWS MCP servers, pinned versions, `timeoutMs`), `README.md`, `SPEC.md`, `LICENSE` (MIT), `SECURITY.md`, `SUPPORT.md`, `CHANGELOG.md`.
- **PR 32** — ADRs A1–A7 under `docs/adr/`: architecture, component contracts, MCP roster, merge contract, escalation heuristic, license/distribution, supply chain. Each follows Context → Decision → Alternatives → Consequences → Revisit, with SPEC backlinks.

#### CI gates and harness

- **PR 2** — Deterministic gates 1–18 in CI. 16 gate scripts under `tests/gates/` (gates 1 and 13 deferred until PR 27); shared bash 3.2-compatible helpers in `lib/common.sh`; cached MCP tool lists; `known-overshoots.txt` for 12 upstream tool names exceeding the 64-char budget (WARN-only). `.markdownlint.jsonc` with rationale per disabled rule. `.github/workflows/gates.yml` runs on Linux bash 5+, macOS bash 3.2, and macOS brew bash 5+.
- **PR 3** — Transcript-replay harness skeleton. `tests/run-transcripts.sh` (validate-only at v0.1.0); first fixture `tests/transcripts/vibe-shallow/`; new `transcript-validate` CI job. Makes gate 19 achievable.

#### Skills — workflow

- **PR 4** — `aws-mcp-routing`: server roster, intent-to-server mapping, per-server fallback markers. First skill ever; gates 5/10/16/17 transition to enforcing PASS.
- **PR 5** — `aws-spec-grounding`: `<server>:<short-key>` citation format, per-artefact grounded-by minimums, opinion-vs-fact boundary tests.
- **PR 6** — `aws-grounding-cache`: ledger schema, TTL classes (pricing/quota 30d, api-shape/region 90d, immutable indefinite), SHA-1 short-key derivation with 8→12-hex collision extension, 8-pattern redaction catalogue.
- **PR 7** — `aws-component-contract`: closed `kind` vocabulary (21 AWS resource kinds), seven canonical body sections, observability triple (metric/log/trace).
- **PR 8** — `aws-layered-diagram`: six required layer tags (`c4-l1`, `c4-l2`, `c4-l3-<container>`, `seq-system`, `seq-component`, `seq-error`), per-layer content rules.
- **PR 9** — `aws-sdlc-workflow`: five SDLC phases, parallel fan-out rule (single message, multi-`Agent`), MCP budgets (8/12/16 for discovery/solution-architect/implementation), 5-rule merge priority (security → facts → cost → convergence → recency). Closes the 6/6 workflow-skill set.

#### Skills — WAF pillars

- **PR 10** — `aws-waf-operational-excellence-skill`: 24 design questions, 22 anti-patterns, 29 checklist items.
- **PR 11** — `aws-waf-security-skill`: 24 design questions, 24 anti-patterns, 27 checklist items.
- **PR 12** — `aws-waf-reliability-skill`: 24 design questions, 25 anti-patterns, 28 checklist items.
- **PR 13** — `aws-waf-performance-efficiency-skill`: 24 design questions, 23 anti-patterns, 28 checklist items.
- **PR 14** — `aws-waf-cost-optimization-skill`: 5-step pricing-model decision tree, 10-class workload eligibility, S3 lifecycle ladder with minimum-storage-duration trap, mandatory cost-allocation tags.
- **PR 15** — `aws-waf-sustainability-skill`: 4-tier carbon region table with deviation policy, Graviton-arm64-default with 6 legitimate `requires-x86` rationales.

Each pillar skill ships `SKILL.md` + `trigger-keywords.txt` + 2–3 references + `assets/<pillar>-review.md.tmpl`.

#### Agents

- **PR 16** — `claude-aws-architect-orchestrator-agent` (L4): full frontmatter (`model`, `effort`, `user-invocable`, `tools` with `Agent`, `max-iterations: 3`, `argument-hint`), 9-section body. Scaffold-only at v0.1.0; full-depth fan-out wiring lands in PR 18. Gate 9 transitions to enforcing PASS.
- **PR 17** — `claude-aws-architect-discovery-agent` (L3): `kb`-only MCP, `aws-spec-grounding`/`aws-grounding-cache`/`aws-mcp-routing` skills, 8-call MCP budget. Outputs `requirements.md` draft + `.grounding-ledger.json`. New fixture `tests/transcripts/sdlc-full-depth/` (gate 19 valid; execution wires up in PR 18).
- **PR 18** — Orchestrator → discovery wiring + transcript executor. Discovery delegation flips to **active**; Design/Plan still emit staged-notice. `tests/run-transcripts.sh` gains `--execute` mode replaying §5.6 depth classification deterministically: shallow asserts no fan-out; single-discovery PASS; multi-specialist DEFERRED until PR 19/21 land.
- **PR 19** — `claude-aws-architect-solution-architect-agent` (L3): `aws-knowledge` + `aws-iac` MCP, fan-out across all six WAF pillars, 12-call budget. Declares parallel fan-out contract (`fan_out_index`) and merge markers (`grounding-deferred`, `budget-exhausted`, `requirements-incomplete`). Outputs `design.md`, per-component `contracts/<slug>.md`, `c4-l1`/`c4-l2` diagram blocks.
- **PR 21** — `claude-aws-architect-implementation-agent` (L3, bundled v0.1.0 specialist): `iac`/`cost`/`iam`/`cw` MCP, 4 pillar skills (security/cost/reliability/operational-excellence), 4 rules (`aws-cdk`/`aws-iam-policy`/`aws-component-contract`/`aws-test`), 12-call budget. Section-merge writes for `contracts/<slug>.md` (IaC/Cost/Security/Acceptance/Observability only). No live AWS writes (read-class MCP only; backed by `aws-api-write-guard`). Wildcard-IAM rejected outside read-only with `iam-advisory-only` fallback. Splits into cost/security/test specialists in v0.2. Closes the v0.1.0 L3 roster (orchestrator + 3 specialists).

#### Rules

- **PR 22** — Rules roster: 9 file-scoped instruction files with canonical frontmatter (`description`, `applyTo`, `inclusion`) — `aws-cdk`, `aws-iam-policy`, `aws-sdk-usage`, `aws-bedrock-prompt`, `aws-test`, `aws-docs`, `aws-diagram`, `aws-component-contract`, `aws-spec-frontmatter`. Gate 8 transitions to enforcing PASS.

#### Powers

- **PR 24** — Three power bundles under `powers/<name>.power.json`:
  - `claude-aws-architect-cdk` — CDK authoring (`iac`/`cost`/`kb` MCP, full skill+command set).
  - `claude-aws-architect-cost` — cost-only (`cost`/`kb` MCP, `aws-waf-cost-optimization-skill`).
  - `claude-aws-architect-security` — security-only (`sec`/`iam`/`kb` MCP, `aws-waf-security-skill`).

  Bedrock and IaC-foundations powers deferred to v0.2. Gate 6 transitions to enforcing PASS.

#### Hooks

- **PR 25** — Hooks core. `hooks/hooks.json` registry (gate 7 schema). `hooks/scripts/lib/dispatcher.sh` (jq-wrapped helpers, JSON `permissionDecision` allow/ask/deny). Two PreToolUse hooks default-on:
  - `secret-scanner.sh` — 5-pattern catalogue (AKIA/ASIA/etc + 16 alphanumerics, secret-key/session-token assignments, PEM private keys, KMS CMK ARNs); denies without echoing the value.
  - `aws-api-write-guard.sh` — 41-verb classifier (create/put/update/delete/…) on `mcp__.*`; emits `ask` with resolved server/tool/verb.

  Gates 7 and 11 transition to enforcing PASS.

- **PR 26** — Four PostToolUse advisory hooks (default-off):
  - `on-cdk-write.sh` — surfaces `cdk synth`/`diff`/cdk-nag nudge on CDK source/config writes.
  - `on-iam-write.sh` — jq parse + heuristic findings (wildcard `Action`/`Resource`, missing `Condition`, trust-policy `Principal.AWS: "*"`); deeper review delegated to `iam:simulate_principal_policy`.
  - `on-bedrock-prompt-write.sh` — checks model-id pinning, guardrail binding, evaluation-hook presence.
  - `aws-test-coverage.sh` — asserts ≥1 sibling test exists for AWS-SDK/CDK-importing files; flags stale tests via `-nt` mtime.

  Fixed latent gate-07 bug (`// "__MISSING__"` → `has(key)`) that masked `enabledByDefault: false`.

#### Setup scripts

- **PR 27** — Four bash 3.2-compatible scripts under `scripts/`:
  - `lib/common.sh` — shared helpers (`PLUGIN_ROOT`/`CONSUMER_ROOT` resolution, `NO_COLOR`-aware loggers, manifest append/read).
  - `doctor.sh` — verifies `uvx`/`jq`/`aws` CLIs, `AWS_PROFILE`/`AWS_REGION`, every stdio MCP server, `sts get-caller-identity`, minimum-IAM policy reference. `--json` mode; exit codes 0–5.
  - `install.sh` — `--symlink` (default) or `--copy` modes; idempotent via `.claude/.claude-aws-architect-installed.jsonl`; never overwrites consumer files.
  - `uninstall.sh` — replays manifest in reverse; `--dry-run` matches real run byte-for-byte (gate 33 contract).
  - `init.sh` — detects host tooling (no auto-install), pre-fetches MCP packages, writes `.claude/settings.json` with `--profile`/`--region`; refuses to clobber unless `--force`; idempotent.

  All scripts shellcheck-clean under `-x`. Six new gate scripts: `gate-01-doctor`, `gate-13-init-idempotent`, `gate-30-clean-roundtrip`, `gate-31-dirty-roundtrip`, `gate-32-install-idempotent`, `gate-33-dryrun-matches-real`. Deferred-gate INFO lines removed. All 24 deterministic gates PASS; gate 33 walks 133 actions.

- **PR 28** — Cross-platform install matrix. `.github/workflows/install-matrix.yml` runs install/doctor/uninstall on `ubuntu-latest` (bash 5+) and `macos-latest` (system bash 3.2 + brew bash 5+). Three legs each smoke-test `--help`, then run three end-to-end roundtrips in fresh `mktemp -d` roots: `--symlink`, `--copy`, and idempotency (`--symlink` × 2). Each leg also runs gates 30–33. Triggers on `paths:` filter. Closes gates 28 and 29 from §11.C.

#### Templates and dogfood

- **PR 29** — Templates under `templates/`. Consumer-facing scaffold the install script copies into `.claude/`:
  - `__feature__/{requirements,design,tasks}.md.tmpl` — full frontmatter and section skeletons.
  - `__feature__/contracts/__slug__.md.tmpl` — canonical 7-section contract.
  - `__feature__/diagrams.d2.tmpl` — six required layer blocks pre-populated.
  - `.claude/claude-aws-architect.local.md.example` — consumer override fields.

  `.tmpl` extension keeps templates outside markdownlint/prettier matchers. Gate 5 PASS (28 frontmatter blocks).

- **PR 30** — Self-dogfood example. `templates/examples/order-processing-pipeline/` (event-driven pipeline, 4 components: `checkout-ingest-api`, `order-validator`, `order-history-store`, `fulfilment-dispatcher`). Full F5+F6 surface — requirements, design (all WAF pillars PASS), tasks, diagrams (all 6 layer tags), 4 contracts, `.grounding-ledger.json`. Capture methodology in `templates/examples/README.md`. Removes the PR 29 `.gitkeep`. Gate 5 PASS (35 frontmatter blocks); gate 19 PASS across all 5 fixtures.

- **PR 31** — Release dogfood (v0.1.0 gate). Plugin designs itself end-to-end. New `.claude/specs/claude-aws-architect/` meta-spec:
  - `requirements.md` — 7 grounded acceptance criteria (depth classification, parallel fan-out, F5/F6 production, grounded-by traceability, IaC pre-deploy validation, cost ROM ceilings, dogfood release-blocker); OQ-1 surfaces closed-vocab gap for non-AWS components.
  - `design.md` — four-agent narrative naming all L3 specialists + L4 orchestrator; 4 design choices with citations (bundled implementation specialist, closed-vocab `kind`, deterministic transcript replay, MIT-zero-telemetry); all 6 WAF pillars PASS.
  - `tasks.md` — 8 tasks (T-01..T-07 done, T-08 in-progress) + 3 validation tasks.
  - `diagrams.d2` — every required layer tag including 4 `c4-l3-<container>` layers.
  - `contracts/` — 4 contracts (orchestrator + 3 L3); out-of-vocab markers `claude-code-agent-l4`/`claude-code-agent-l3` flagged in `## Open questions`.
  - `.grounding-ledger.json` — 6 entries (8-char short-keys), 2 `kb` entries satisfying §13.G.

  New repo-root `CLAUDE.md` per §H2 (entry-point pointers, hook posture, house rules). `.gitignore` updated per §H4: `.claude/claude-aws-architect.local.md` and `.claude/specs/**/.grounding-ledger.json` ignored, with `!.claude/specs/claude-aws-architect/.grounding-ledger.json` re-included as canonical reference. All 24 gates PASS; gate 5 at 42 frontmatter blocks.

#### Security and supply chain

- **PR 28a** — Security infrastructure:
  - [`docs/threat-model.md`](./docs/threat-model.md) — 3 trust boundaries; 4 threat classes (T1 prompt-injection-via-MCP, T2 hook-script-abuse, T3 install-time-tampering, T4 secret-exfiltration-via-grounding-ledger).
  - [`.github/dependabot.yml`](./.github/dependabot.yml) — GitHub Actions only at v0.1.0; weekly Mon 06:00 UTC, grouped minor/patch, `chore(deps)` prefix.
  - [`.github/workflows/mcp-version-skew.yml`](./.github/workflows/mcp-version-skew.yml) — nightly `17 4 * * *` jq scan of every `uvx` MCP server against PyPI JSON; pre-release shapes filtered; idempotent issue lifecycle; `actions/checkout` SHA-pinned.

  `SECURITY.md` updated with inline links.

- **PR 28b** — Issue and PR templates. `.github/ISSUE_TEMPLATE/`: `config.yml` (blank issues disabled; routes to Discussions / private advisories / `SUPPORT.md`), `bug_report.yml` (preflight, repro, plugin/Claude Code/OS metadata, MCP snapshot, severity dropdown), `feature_request.yml` (problem-first, surface-area select, target-version triage). `.github/pull_request_template.md` mirrors `PR-CONVENTIONS.md`. `SUPPORT.md` gains `?template=` deep links.

- **PR 28b follow-up** — `.github/ISSUE_TEMPLATE/security.yml`. Hard-redirect form pointing reporters to the private GitHub Security Advisory and `[security]` email channel; requires acknowledgement that the form is a redirect.

[Unreleased]: https://github.com/odere-pro/claude-aws-architect/compare/main...HEAD
