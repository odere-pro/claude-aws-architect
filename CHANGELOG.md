# Changelog

All notable changes to `claude-aws-architect` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Per [SPEC §N9](./docs/plan/SPEC-v4.md), one entry is added per merged PR. The plugin starts at `v0.1.0` — no `v0.0.x` versions exist. Until v0.1.0 is tagged (per [PR-PLAN.md](./docs/plan/PR-PLAN.md) PR 31, which gates the tag on the §11.E release dogfood), all PR entries accumulate under `## [Unreleased]` and are promoted to `## [0.1.0]` at tag time.

## [Unreleased]

### Added

- **PR 0**: Planning import. `docs/plan/SPEC-v4.md` (full v4 declarative spec, sections 0–18), `docs/plan/PR-PLAN.md` (33-PR execution roadmap with dependencies and parallel-safe flags), `docs/plan/PR-CONVENTIONS.md` (branch naming, commit format, merge strategy).
- **PR 1**: Plugin scaffold. `.claude-plugin/plugin.json` (manifest with `name`, `version`, `engines.claude-code`), `.mcp.json` (6 AWS MCP servers with short identifiers per O3, pinned versions per §16.2, `timeoutMs` per O2), `README.md` (sections per §N7 ordering plus Trademark notice per §15.4), `SPEC.md` (sections per §N8 ordering), `LICENSE` (MIT), `SECURITY.md` (vulnerability disclosure per §16.1), `SUPPORT.md` (community-driven posture per §17.3), `CHANGELOG.md` (this file).

[Unreleased]: https://github.com/odere-pro/claude-aws-architect/compare/main...HEAD
