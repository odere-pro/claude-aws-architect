# SPEC — `claude-aws-architect` v0.1.0

User-facing specification of the plugin's architecture, contracts, and validation gates. The full design rationale lives at [docs/plan/SPEC-v4.md](./docs/plan/SPEC-v4.md); this file is the merged, public-facing reference.

> **Status: pre-release scaffold.** Sections below describe the v0.1.0 target. Items marked _(pending PR N)_ land in the noted pull request per [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md).

## Architecture

Four layers, loosely coupled:

1. **Layer 1 — MCP servers.** Six AWS MCP servers (see § MCP servers) provide grounded knowledge: docs, IaC validation, pricing, security findings, IAM, observability.
2. **Layer 2 — Skills.** Twelve plugin-authored skills (six workflow + six WAF pillar) under `skills/`. _(pending PRs 4–15)_
3. **Layer 3 — Agents.** One L4 orchestrator + three L3 specialists (`discovery`, `solution-architect`, `implementation`) under `agents/`. _(pending PRs 16–21)_
4. **Layer 4 — Surface.** Three slash commands (`/aws`, `/aws-spec`, `/aws-doctor`), three Powers, and a hooks registry. _(pending PRs 22–28)_

The orchestrator fans out L3 specialists in parallel (≤3 concurrent calls per turn) and merges results per the conflict-resolution priority order in [SPEC-v4 §5.5](./docs/plan/SPEC-v4.md).

## MCP servers

Six servers wired at v0.1.0. Each `.mcp.json` key is a short identifier (per O3 tool-name budget) mapping to the descriptive logical name used in skills and agents.

| Key    | Logical name                | Transport | Package                                        | Version | Timeout |
| ------ | --------------------------- | --------- | ---------------------------------------------- | ------- | ------- |
| `kb`   | `aws-knowledge`             | http      | `https://knowledge-mcp.global.api.aws`         | 0.1.0   | 30000ms |
| `iac`  | `aws-iac`                   | stdio     | `awslabs.aws-iac-mcp-server`                   | 1.0.17  | 60000ms |
| `cost` | `aws-pricing`               | stdio     | `awslabs.aws-pricing-mcp-server`               | 1.0.28  | 30000ms |
| `sec`  | `well-architected-security` | stdio     | `awslabs.well-architected-security-mcp-server` | 0.1.7   | 60000ms |
| `iam`  | `iam`                       | stdio     | `awslabs.iam-mcp-server`                       | 1.0.18  | 30000ms |
| `cw`   | `cloudwatch`                | stdio     | `awslabs.cloudwatch-mcp-server`                | 0.0.26  | 30000ms |

Version pins are enforced by gate 12 in CI. Bumping a pin is a `feat(deps)` PR.

Degraded-mode behaviour per [SPEC-v4 §3.5](./docs/plan/SPEC-v4.md): every per-server failure surfaces a labelled marker (`grounding-deferred`, `validation-advisory`, etc.) in the merged orchestrator output rather than silently dropping signal.

## Skills

_(Pending PRs 4–15.)_ Twelve skills ship at v0.1.0:

- **Workflow skills (6):** `aws-sdlc-workflow`, `aws-spec-grounding`, `aws-grounding-cache`, `aws-component-contract`, `aws-layered-diagram`, `aws-mcp-routing`.
- **WAF pillar skills (6):** `aws-waf-operational-excellence-skill`, `aws-waf-security-skill`, `aws-waf-reliability-skill`, `aws-waf-performance-efficiency-skill`, `aws-waf-cost-optimization-skill`, `aws-waf-sustainability-skill`.

Each skill must satisfy the canonical declaration contract: SKILL.md frontmatter (`name`, `description`, `version`), required body sections (When to Use · Procedure · **Gotchas (mandatory)** · Boundaries · Quality Checks), ≤500-line body budget, and a sibling `trigger-keywords.txt`. Enforced by gates 10, 16, 17.

## Agents

_(Pending PRs 16–21.)_

| #   | Agent                                           | Layer | Role                                          |
| --- | ----------------------------------------------- | ----- | --------------------------------------------- |
| 0   | `claude-aws-architect-orchestrator-agent`       | L4    | Entry point, parallel fan-out, merge contract |
| 1   | `claude-aws-architect-discovery-agent`          | L3    | Discovery + grounding ledger                  |
| 2   | `claude-aws-architect-solution-architect-agent` | L3    | Solution architecture + design choice         |
| 3   | `claude-aws-architect-implementation-agent`     | L3    | Bundled IaC + cost ROM + IAM + tests          |

Every agent file satisfies the canonical agent declaration contract: frontmatter (`name`, `description`, `model`, `effort`, `user-invocable`, `tools`), nine ordered H2 sections (Role · Requirements · Dependencies · Operating Principles · Routing Map · Workflow · Output Rules · Boundaries · Quality Checks). The orchestrator additionally declares `max-iterations` (default 3) and an `Agent` tool. Enforced by gate 9.

## Rules

_(Pending PR 22.)_ Nine file-scoped instruction rules under `rules/` raise per-file accuracy. See [docs/plan/SPEC-v4.md §6.2](./docs/plan/SPEC-v4.md) for the full mandate. Enforced by gate 8.

## Powers

_(Pending PR 24.)_ Three Powers ship at v0.1.0: `claude-aws-architect-cdk`, `claude-aws-architect-cost`, `claude-aws-architect-security`. Each is a JSON file under `powers/` declaring `name`, `version`, `description`, and arrays of `mcpServers`, `skills`, `hooks`, `commands` it bundles. Enforced by gate 6.

## Hooks

_(Pending PRs 25–26.)_ Hooks registry at `hooks/hooks.json` with seven scripts under `hooks/scripts/`. Default-enabled: `aws-secret-scanner`, `aws-api-write-guard`. Opt-in via `.claude/claude-aws-architect.local.md`. Hook-script contract enforced by gate 11.

## Schemas

Canonical schemas referenced throughout the plugin:

- **`powers/<name>.power.json`** — per [SPEC-v4 §9.1](./docs/plan/SPEC-v4.md). Required keys: `name`, `version`, `description`, `mcpServers[]`, `skills[]`, `hooks[]`, `commands[]`.
- **`hooks/hooks.json` entry** — per §9.2. Required: `name`, `event`, `matcher`, `command`, `enabledByDefault`. Optional: `filePattern`, `enabledWhen`.
- **Spec-doc frontmatter** — per §9.3. Required: `feature`, `created`, `updated`, `status`, `grounded-by[]`.
- **Component-contract frontmatter** — per §9.4. Required: `component`, `kind`, `version`, `status`, `talks-to[]`, `grounded-by[]`.
- **Grounded-by citation** — per §9.5. Form: `<server-key>:<short-key>`. Short-key is first 8 hex of SHA-1 of canonicalised query (extends to 12 on collision).
- **`diagrams.d2` layer tags** — per §9.6. Required: `c4-l1`, `c4-l2`, `c4-l3-<container>`, `seq-system`, `seq-component`, `seq-error`.

## Validation gates

Eighteen deterministic gates (run locally and in CI) plus nine runtime gates (transcript-replay) plus four install-safety gates plus a release gate. Full enumeration at [SPEC-v4 §11](./docs/plan/SPEC-v4.md).

| Tier           | Gates | Where enforced                                           |
| -------------- | ----- | -------------------------------------------------------- |
| Deterministic  | 1–18  | `.github/workflows/` (lands PR 2)                        |
| Runtime        | 19–27 | `tests/run-transcripts.sh` (lands PR 3, extended PR 18+) |
| Cross-platform | 28–29 | CI matrix on `ubuntu-latest`, `macos-latest` (PR 28)     |
| Install-safety | 30–33 | `tests/install/` fixtures (PR 27)                        |
| Release        | 34    | Self-design dogfood (PR 31, blocks tagging)              |

This PR (1) makes gates **2** (`plugin.json` parses, has `name` + `engines.claude-code`), **12** (`.mcp.json` lists exactly the 6 servers from §3.1, each with pinned `version` and `timeoutMs`), and **15** (README has `## Trademark notice` with the four declarative bullets) achievable. CI enforcement of these gates lands in PR 2.

## Versioning

- **`plugin.json#version`**: SemVer per N9. v0.1.0 is the first tag.
- **`plugin.json#engines.claude-code`**: SemVer range per O1. Bumping requires a `BREAKING` CHANGELOG entry.
- **`.mcp.json` server pins**: bumped via `feat(deps)` PR with rationale in commit body. Per §17.4.
- **Pre-1.0 minors may break public spec interfaces**; CHANGELOG calls out every break.
- **One supported version at a time** at v0.1.x. Hotfixes land on `release/0.1.x` when v0.2 is in development.
