# Changelog

All notable changes to `claude-aws-architect` are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

One entry per merged change, keyed by short commit SHA (linked to the commit on GitHub). The plugin starts at `v0.1.0`; until that tag ships (gated by [PR-PLAN.md](./docs/plan/PR-PLAN.md) PR 31), entries accumulate under `[Unreleased]` and are promoted on tag.

## [Unreleased]

### Added

#### Planning and scaffold

- **[`92be854`](https://github.com/odere-pro/claude-aws-architect/commit/92be854)** — Planning import: `docs/plan/SPEC-v4.md`, `docs/plan/PR-PLAN.md`, `docs/plan/PR-CONVENTIONS.md`.
- **[`6ada063`](https://github.com/odere-pro/claude-aws-architect/commit/6ada063)** — Plugin scaffold + gates 1–18 + transcript harness skeleton (originally split as PR 1/2/3, landed in one commit). `.claude-plugin/plugin.json`, `.mcp.json` (6 AWS MCP servers, pinned versions, `timeoutMs`), `README.md`, `SPEC.md`, `LICENSE` (MIT), `SECURITY.md`, `SUPPORT.md`, `CHANGELOG.md`. 16 gate scripts under `tests/gates/` (gates 1 and 13 deferred until [`9cc48e1`](https://github.com/odere-pro/claude-aws-architect/commit/9cc48e1)); shared bash 3.2-compatible helpers; cached MCP tool lists; `known-overshoots.txt` for 12 upstream tool names exceeding the 64-char budget. `tests/run-transcripts.sh` (validate-only at v0.1.0); first fixture `tests/transcripts/vibe-shallow/`; `transcript-validate` CI job. `.github/workflows/gates.yml` runs on Linux bash 5+, macOS bash 3.2, and macOS brew bash 5+.
- **[`052c59a`](https://github.com/odere-pro/claude-aws-architect/commit/052c59a)** — ADRs A1–A7 under `docs/adr/`: architecture, component contracts, MCP roster, merge contract, escalation heuristic, license/distribution, supply chain. Each follows Context → Decision → Alternatives → Consequences → Revisit, with SPEC backlinks.

#### Skills — workflow

- **[`28b7f00`](https://github.com/odere-pro/claude-aws-architect/commit/28b7f00)** — `aws-mcp-routing`: server roster, intent-to-server mapping, per-server fallback markers. First skill ever; gates 5/10/16/17 transition to enforcing PASS.
- **[`1acda1f`](https://github.com/odere-pro/claude-aws-architect/commit/1acda1f)** — `aws-spec-grounding`: `<server>:<short-key>` citation format, per-artefact grounded-by minimums, opinion-vs-fact boundary tests.
- **[`51a30b6`](https://github.com/odere-pro/claude-aws-architect/commit/51a30b6)** — `aws-grounding-cache`: ledger schema, TTL classes (pricing/quota 30d, api-shape/region 90d, immutable indefinite), SHA-1 short-key derivation with 8→12-hex collision extension, 8-pattern redaction catalogue.
- **[`f261ebf`](https://github.com/odere-pro/claude-aws-architect/commit/f261ebf)** — `aws-component-contract`: closed `kind` vocabulary (21 AWS resource kinds), seven canonical body sections, observability triple (metric/log/trace).
- **[`dbf723f`](https://github.com/odere-pro/claude-aws-architect/commit/dbf723f)** — `aws-layered-diagram`: six required layer tags (`c4-l1`, `c4-l2`, `c4-l3-<container>`, `seq-system`, `seq-component`, `seq-error`), per-layer content rules.
- **[`5d977ad`](https://github.com/odere-pro/claude-aws-architect/commit/5d977ad)** — `aws-sdlc-workflow`: five SDLC phases, parallel fan-out rule (single message, multi-`Agent`), MCP budgets (8/12/16 for discovery/solution-architect/implementation), 5-rule merge priority (security → facts → cost → convergence → recency). Closes the 6/6 workflow-skill set.

#### Skills — WAF pillars

- **[`a5bfbef`](https://github.com/odere-pro/claude-aws-architect/commit/a5bfbef)** — `aws-waf-operational-excellence-skill`: 24 design questions, 22 anti-patterns, 29 checklist items.
- **[`246d01e`](https://github.com/odere-pro/claude-aws-architect/commit/246d01e)** — `aws-waf-security-skill`: 24 design questions, 24 anti-patterns, 27 checklist items.
- **[`811f7c4`](https://github.com/odere-pro/claude-aws-architect/commit/811f7c4)** — `aws-waf-reliability-skill`: 24 design questions, 25 anti-patterns, 28 checklist items.
- **[`1e256c5`](https://github.com/odere-pro/claude-aws-architect/commit/1e256c5)** — `aws-waf-performance-efficiency-skill`: 24 design questions, 23 anti-patterns, 28 checklist items.
- **[`749d186`](https://github.com/odere-pro/claude-aws-architect/commit/749d186)** — `aws-waf-cost-optimization-skill`: 5-step pricing-model decision tree, 10-class workload eligibility, S3 lifecycle ladder with minimum-storage-duration trap, mandatory cost-allocation tags.
- **[`6aab0b9`](https://github.com/odere-pro/claude-aws-architect/commit/6aab0b9)** — `aws-waf-sustainability-skill`: 4-tier carbon region table with deviation policy, Graviton-arm64-default with 6 legitimate `requires-x86` rationales.

Each pillar skill ships `SKILL.md` + `trigger-keywords.txt` + 2–3 references + `assets/<pillar>-review.md.tmpl`.

#### Agents

- **[`beb21ad`](https://github.com/odere-pro/claude-aws-architect/commit/beb21ad)** — `claude-aws-architect-orchestrator-agent` (L4): full frontmatter (`model`, `effort`, `user-invocable`, `tools` with `Agent`, `max-iterations: 3`, `argument-hint`), 9-section body. Scaffold-only at v0.1.0; full-depth fan-out wiring lands in [`41b9a37`](https://github.com/odere-pro/claude-aws-architect/commit/41b9a37). Gate 9 transitions to enforcing PASS.
- **[`ddf0f48`](https://github.com/odere-pro/claude-aws-architect/commit/ddf0f48)** — `claude-aws-architect-discovery-agent` (L3): `kb`-only MCP, `aws-spec-grounding`/`aws-grounding-cache`/`aws-mcp-routing` skills, 8-call MCP budget. Outputs `requirements.md` draft + `.grounding-ledger.json`. New fixture `tests/transcripts/sdlc-full-depth/` (gate 19 valid; execution wires up next).
- **[`41b9a37`](https://github.com/odere-pro/claude-aws-architect/commit/41b9a37)** — Orchestrator → discovery wiring + transcript executor. Discovery delegation flips to **active**; Design/Plan still emit staged-notice. `tests/run-transcripts.sh` gains `--execute` mode replaying §5.6 depth classification deterministically: shallow asserts no fan-out; single-discovery PASS; multi-specialist DEFERRED until solution-architect / implementation land.
- **[`4a87f49`](https://github.com/odere-pro/claude-aws-architect/commit/4a87f49)** — `claude-aws-architect-solution-architect-agent` (L3): `aws-knowledge` + `aws-iac` MCP, fan-out across all six WAF pillars, 12-call budget. Declares parallel fan-out contract (`fan_out_index`) and merge markers (`grounding-deferred`, `budget-exhausted`, `requirements-incomplete`). Outputs `design.md`, per-component `contracts/<slug>.md`, `c4-l1`/`c4-l2` diagram blocks.
- **[`7cef2d3`](https://github.com/odere-pro/claude-aws-architect/commit/7cef2d3)** — `claude-aws-architect-implementation-agent` (L3, bundled v0.1.0 specialist): `iac`/`cost`/`iam`/`cw` MCP, 4 pillar skills (security/cost/reliability/operational-excellence), 4 rules (`aws-cdk`/`aws-iam-policy`/`aws-component-contract`/`aws-test`), 12-call budget. Section-merge writes for `contracts/<slug>.md` (IaC/Cost/Security/Acceptance/Observability only). No live AWS writes (read-class MCP only; backed by `aws-api-write-guard`). Wildcard-IAM rejected outside read-only with `iam-advisory-only` fallback. Splits into cost/security/test specialists in v0.2. Closes the v0.1.0 L3 roster (orchestrator + 3 specialists).

#### Rules

- **[`694ef8f`](https://github.com/odere-pro/claude-aws-architect/commit/694ef8f)** — Rules roster: 9 file-scoped instruction files with canonical frontmatter (`description`, `applyTo`, `inclusion`) — `aws-cdk`, `aws-iam-policy`, `aws-sdk-usage`, `aws-bedrock-prompt`, `aws-test`, `aws-docs`, `aws-diagram`, `aws-component-contract`, `aws-spec-frontmatter`. Gate 8 transitions to enforcing PASS.

#### Powers

- **[`c921c7c`](https://github.com/odere-pro/claude-aws-architect/commit/c921c7c)** — Three power bundles under `powers/<name>.power.json`:
  - `claude-aws-architect-cdk` — CDK authoring (`iac`/`cost`/`kb` MCP, full skill+command set).
  - `claude-aws-architect-cost` — cost-only (`cost`/`kb` MCP, `aws-waf-cost-optimization-skill`).
  - `claude-aws-architect-security` — security-only (`sec`/`iam`/`kb` MCP, `aws-waf-security-skill`).

  Bedrock and IaC-foundations powers deferred to v0.2. Gate 6 transitions to enforcing PASS.

#### Hooks

- **[`7b425de`](https://github.com/odere-pro/claude-aws-architect/commit/7b425de)** — Hooks core. `hooks/hooks.json` registry (gate 7 schema). `hooks/scripts/lib/dispatcher.sh` (jq-wrapped helpers, JSON `permissionDecision` allow/ask/deny). Two PreToolUse hooks default-on:
  - `aws-secret-scanner.sh` — 5-pattern catalogue (AKIA/ASIA/etc + 16 alphanumerics, secret-key/session-token assignments, PEM private keys, KMS CMK ARNs); denies without echoing the value.
  - `aws-api-write-guard.sh` — 41-verb classifier (create/put/update/delete/…) on `mcp__.*`; emits `ask` with resolved server/tool/verb.

  Gates 7 and 11 transition to enforcing PASS.

- **[`fa53925`](https://github.com/odere-pro/claude-aws-architect/commit/fa53925)** — Four PostToolUse advisory hooks (default-off):
  - `aws-on-cdk-write.sh` — surfaces `cdk synth`/`diff`/cdk-nag nudge on CDK source/config writes.
  - `aws-on-iam-write.sh` — jq parse + heuristic findings (wildcard `Action`/`Resource`, missing `Condition`, trust-policy `Principal.AWS: "*"`); deeper review delegated to `iam:simulate_principal_policy`.
  - `aws-on-bedrock-prompt-write.sh` — checks model-id pinning, guardrail binding, evaluation-hook presence.
  - `aws-test-coverage.sh` — asserts ≥1 sibling test exists for AWS-SDK/CDK-importing files; flags stale tests via `-nt` mtime.

  Fixed latent gate-07 bug (`// "__MISSING__"` → `has(key)`) that masked `enabledByDefault: false`. Names later normalised to a uniform `aws-` prefix in [`839a4cf`](https://github.com/odere-pro/claude-aws-architect/commit/839a4cf).

#### Setup scripts

- **[`9cc48e1`](https://github.com/odere-pro/claude-aws-architect/commit/9cc48e1)** — Four bash 3.2-compatible scripts under `scripts/`:
  - `lib/common.sh` — shared helpers (`PLUGIN_ROOT`/`CONSUMER_ROOT` resolution, `NO_COLOR`-aware loggers, manifest append/read).
  - `doctor.sh` — verifies `uvx`/`jq`/`aws` CLIs, `AWS_PROFILE`/`AWS_REGION`, every stdio MCP server, `sts get-caller-identity`, minimum-IAM policy reference. `--json` mode; exit codes 0–5.
  - `install.sh` — `--symlink` (default) or `--copy` modes; idempotent via `.claude/.claude-aws-architect-installed.jsonl`; never overwrites consumer files.
  - `uninstall.sh` — replays manifest in reverse; `--dry-run` matches real run byte-for-byte (gate 33 contract).
  - `init.sh` — detects host tooling (no auto-install), pre-fetches MCP packages, writes `.claude/settings.json` with `--profile`/`--region`; refuses to clobber unless `--force`; idempotent.

  All scripts shellcheck-clean under `-x`. Six new gate scripts: `gate-01-doctor`, `gate-13-init-idempotent`, `gate-30-clean-roundtrip`, `gate-31-dirty-roundtrip`, `gate-32-install-idempotent`, `gate-33-dryrun-matches-real`. Deferred-gate INFO lines removed. All 24 deterministic gates PASS; gate 33 walks 133 actions.

- **[`73a948a`](https://github.com/odere-pro/claude-aws-architect/commit/73a948a)** — Cross-platform install matrix. `.github/workflows/install-matrix.yml` runs install/doctor/uninstall on `ubuntu-latest` (bash 5+) and `macos-latest` (system bash 3.2 + brew bash 5+). Three legs each smoke-test `--help`, then run three end-to-end roundtrips in fresh `mktemp -d` roots: `--symlink`, `--copy`, and idempotency (`--symlink` × 2). Each leg also runs gates 30–33. Triggers on `paths:` filter. Closes gates 28 and 29 from §11.C.

#### Templates and dogfood

- **[`8aa079b`](https://github.com/odere-pro/claude-aws-architect/commit/8aa079b)** — Templates under `templates/`. Consumer-facing scaffold the install script copies into `.claude/`:
  - `__feature__/{requirements,design,tasks}.md.tmpl` — full frontmatter and section skeletons.
  - `__feature__/contracts/__slug__.md.tmpl` — canonical 7-section contract.
  - `__feature__/diagrams.d2.tmpl` — six required layer blocks pre-populated.
  - `.claude/claude-aws-architect.local.md.example` — consumer override fields.

  `.tmpl` extension keeps templates outside markdownlint/prettier matchers. Gate 5 PASS (28 frontmatter blocks).

- **[`df74976`](https://github.com/odere-pro/claude-aws-architect/commit/df74976)** — Self-dogfood example. `templates/examples/order-processing-pipeline/` (event-driven pipeline, 4 components: `checkout-ingest-api`, `order-validator`, `order-history-store`, `fulfilment-dispatcher`). Full F5+F6 surface — requirements, design (all WAF pillars PASS), tasks, diagrams (all 6 layer tags), 4 contracts, `.grounding-ledger.json`. Capture methodology in `templates/examples/README.md`. Removes the [`8aa079b`](https://github.com/odere-pro/claude-aws-architect/commit/8aa079b) `.gitkeep`. Gate 5 PASS (35 frontmatter blocks); gate 19 PASS across all 5 fixtures.

- **[`41e4c97`](https://github.com/odere-pro/claude-aws-architect/commit/41e4c97)** — Release dogfood (v0.1.0 gate). Plugin designs itself end-to-end. New `.claude/specs/claude-aws-architect/` meta-spec:
  - `requirements.md` — 7 grounded acceptance criteria (depth classification, parallel fan-out, F5/F6 production, grounded-by traceability, IaC pre-deploy validation, cost ROM ceilings, dogfood release-blocker); OQ-1 surfaces closed-vocab gap for non-AWS components.
  - `design.md` — four-agent narrative naming all L3 specialists + L4 orchestrator; 4 design choices with citations (bundled implementation specialist, closed-vocab `kind`, deterministic transcript replay, MIT-zero-telemetry); all 6 WAF pillars PASS.
  - `tasks.md` — 8 tasks (T-01..T-07 done, T-08 in-progress) + 3 validation tasks.
  - `diagrams.d2` — every required layer tag including 4 `c4-l3-<container>` layers.
  - `contracts/` — 4 contracts (orchestrator + 3 L3); out-of-vocab markers `claude-code-agent-l4`/`claude-code-agent-l3` flagged in `## Open questions`.
  - `.grounding-ledger.json` — 6 entries (8-char short-keys), 2 `kb` entries satisfying §13.G.

  New repo-root `CLAUDE.md` per §H2 (entry-point pointers, hook posture, house rules). `.gitignore` updated per §H4: `.claude/claude-aws-architect.local.md` and `.claude/specs/**/.grounding-ledger.json` ignored, with `!.claude/specs/claude-aws-architect/.grounding-ledger.json` re-included as canonical reference. All 24 gates PASS; gate 5 at 42 frontmatter blocks.

#### Security and supply chain

- **[`ed4e03b`](https://github.com/odere-pro/claude-aws-architect/commit/ed4e03b)** — Security infrastructure:
  - [`docs/threat-model.md`](./docs/threat-model.md) — 3 trust boundaries; 4 threat classes (T1 prompt-injection-via-MCP, T2 hook-script-abuse, T3 install-time-tampering, T4 secret-exfiltration-via-grounding-ledger).
  - [`.github/dependabot.yml`](./.github/dependabot.yml) — GitHub Actions only at v0.1.0; weekly Mon 06:00 UTC, grouped minor/patch, `chore(deps)` prefix.
  - [`.github/workflows/mcp-version-skew.yml`](./.github/workflows/mcp-version-skew.yml) — nightly `17 4 * * *` jq scan of every `uvx` MCP server against PyPI JSON; pre-release shapes filtered; idempotent issue lifecycle; `actions/checkout` SHA-pinned.

  `SECURITY.md` updated with inline links.

- **[`c6a8d8a`](https://github.com/odere-pro/claude-aws-architect/commit/c6a8d8a)** — Issue and PR templates. `.github/ISSUE_TEMPLATE/`: `config.yml` (blank issues disabled; routes to Discussions / private advisories / `SUPPORT.md`), `bug_report.yml` (preflight, repro, plugin/Claude Code/OS metadata, MCP snapshot, severity dropdown), `feature_request.yml` (problem-first, surface-area select, target-version triage). `.github/pull_request_template.md` mirrors `PR-CONVENTIONS.md`. `SUPPORT.md` gains `?template=` deep links.

- **[`caff52b`](https://github.com/odere-pro/claude-aws-architect/commit/caff52b)** — `.github/ISSUE_TEMPLATE/security.yml`. Hard-redirect form pointing reporters to the private GitHub Security Advisory and `[security]` email channel; requires acknowledgement that the form is a redirect.

### Changed

- **[`839a4cf`](https://github.com/odere-pro/claude-aws-architect/commit/839a4cf)** — Uniform `aws-` prefix on hook names and script filenames to avoid collisions when installed alongside other plugins or a global `~/.claude/`. Renames `secret-scanner` → `aws-secret-scanner`, `on-cdk-write` → `aws-on-cdk-write`, `on-iam-write` → `aws-on-iam-write`, `on-bedrock-prompt-write` → `aws-on-bedrock-prompt-write`. `aws-api-write-guard` and `aws-test-coverage` already prefixed. Updates references in `README.md`, `SPEC.md`, `CLAUDE.md`, `hooks/README.md`, `docs/threat-model.md`, `docs/plan/SPEC-v4.md` (normative tables only), three power bundles, the dogfood spec, the consumer template, and the transcript-fixture README. New "Naming policy for shipped artefacts" section in `CLAUDE.md` codifies the convention.

### Fixed

- **[`6aca2ee`](https://github.com/odere-pro/claude-aws-architect/commit/6aca2ee)** — Wire runtime gates 20–27 in `tests/run-transcripts.sh`. The `--execute` mode previously emitted only gate 19 and reported the four non-shallow fixtures as `DEFERRED`; the contract assertions for `sdlc-full-depth` (gates 20 ≥2 specialist `Agent` calls in single turn, 21 F5/F6 artefacts, 22 kb grounding precedes first `Write`, 23 per-component contracts, 24 `diagrams.d2` declared), `merge-conflict` (gate 25 `priority_rules_applied` shape per §5.5), `degraded-mcp` (gate 26 `degraded_signals` fallback markers per §3.5), and `iteration-cap` (gate 27 three iterations + `iteration-cap-reached` marker per O4) now run inline against `expected-tools.jsonl` and `expected-merge.json`. `--execute` exits 0 with all gates 19–27 PASS; deferred bookkeeping removed. Also corrects `SPEC.md` § Hooks: "seven scripts under `hooks/scripts/`" → "six scripts" to match the gate-7/11 enforced count.

[Unreleased]: https://github.com/odere-pro/claude-aws-architect/compare/main...HEAD
