# Changelog

All notable changes to `claude-aws-architect` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Per [SPEC §N9](./docs/plan/SPEC-v4.md), one entry is added per merged PR. The plugin starts at `v0.1.0` — no `v0.0.x` versions exist. Until v0.1.0 is tagged (per [PR-PLAN.md](./docs/plan/PR-PLAN.md) PR 31, which gates the tag on the §11.E release dogfood), all PR entries accumulate under `## [Unreleased]` and are promoted to `## [0.1.0]` at tag time.

## [Unreleased]

### Added

- **PR 0**: Planning import. `docs/plan/SPEC-v4.md` (full v4 declarative spec, sections 0–18), `docs/plan/PR-PLAN.md` (33-PR execution roadmap with dependencies and parallel-safe flags), `docs/plan/PR-CONVENTIONS.md` (branch naming, commit format, merge strategy).
- **PR 1**: Plugin scaffold. `.claude-plugin/plugin.json` (manifest with `name`, `version`, `engines.claude-code`), `.mcp.json` (6 AWS MCP servers with short identifiers per O3, pinned versions per §16.2, `timeoutMs` per O2), `README.md` (sections per §N7 ordering plus Trademark notice per §15.4), `SPEC.md` (sections per §N8 ordering), `LICENSE` (MIT), `SECURITY.md` (vulnerability disclosure per §16.1), `SUPPORT.md` (community-driven posture per §17.3), `CHANGELOG.md` (this file).
- **PR 2**: Deterministic gates 1–18 in CI. 16 gate scripts under `tests/gates/` (gates 1 and 13 deferred until PR 27 ships init/doctor); `tests/gates/lib/common.sh` shared helpers (bash 3.2 compatible — uses `read_into` instead of `mapfile`); cached MCP tool lists under `tests/gates/cache/tools-<key>.txt` (seeded from upstream awslabs READMEs); `tests/gates/cache/known-overshoots.txt` documenting 12 upstream-controlled tool names that exceed O3's 64-char budget (WARN-only, with citation of which agent/skill depends on each); `.markdownlint.jsonc` config with rationale for every disabled rule; `.github/workflows/gates.yml` with three jobs (Linux bash 5+, macOS system bash 3.2, macOS brew bash 5+) — explicit `/bin/bash` invocation on macOS asserts the §8.2 "tested on macOS bash 3.2" claim. Markdown auto-formatted with prettier 3.6.2.

[Unreleased]: https://github.com/odere-pro/claude-aws-architect/compare/main...HEAD
