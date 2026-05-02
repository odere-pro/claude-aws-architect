# Security policy

`claude-aws-architect` takes security reports seriously. This document describes how to disclose vulnerabilities and what is in or out of scope for this plugin.

## Reporting a vulnerability

**Please do not file public GitHub issues for security vulnerabilities.** Use one of the following private channels:

- **Email**: `odere.pro@gmail.com` with subject prefix `[security]`.
- **GitHub Security Advisory**: open a draft at <https://github.com/odere-pro/claude-aws-architect/security/advisories/new>.

Include in the report:

- Affected version(s) (`plugin.json#version`)
- A description of the vulnerability and its impact
- Steps to reproduce, ideally with a minimal repro repo
- Your suggested mitigation, if any

## Response window

- **Acknowledgement**: best-effort within 7 days of receipt.
- **Triage and fix**: no SLA at v0.1.x. Critical issues take priority over feature work.
- **Disclosure**: coordinated. The reporter is credited in the fix's CHANGELOG entry unless they request anonymity.

## In-scope

The following components are in scope for security reports:

- Hook scripts under `hooks/scripts/` — particularly anything touching shell expansion, file paths, or external commands.
- Install/uninstall scripts under `scripts/` — particularly file-system operations and symlink handling.
- `.mcp.json` server configuration — version pinning, timeout enforcement, transport selection.
- Agent files under `agents/` and skill files under `skills/` — instruction patterns that could enable prompt-injection escapes or tool-call abuse.
- Power JSON files under `powers/` — schema validation gaps that could mis-bundle servers or hooks.

## Out of scope

The following are not in scope here; report them to the upstream maintainer:

- **Vulnerabilities in upstream MCP servers** (`awslabs.*`) — report to AWS Labs at <https://github.com/awslabs/mcp/security>.
- **Vulnerabilities in Claude Code** itself — report to Anthropic per <https://www.anthropic.com/security>.
- **Vulnerabilities in `uvx` / `uv`** — report to <https://github.com/astral-sh/uv/security>.
- **User-authored content under `.claude/specs/`** — this is consumer code, not plugin code.
- **AWS API behaviour** — report to AWS Security at <https://aws.amazon.com/security/vulnerability-reporting/>.

## Threat model

Documented in [`docs/threat-model.md`](./docs/threat-model.md). Four threat classes enumerated:

1. **Prompt injection via MCP server output** — mitigated by file-scoped rules + merge-contract Open Questions.
2. **Hook script abuse** — mitigated by `set -euo pipefail`, quoted variables, scope confinement.
3. **Install-time tampering** — mitigated by install-safety gates 30–33 (byte-identical-state assertions).
4. **Secret exfiltration via grounding ledger** — mitigated by secret redaction on insert in `aws-grounding-cache` skill.

## Supply chain

- All `.mcp.json` server entries pin an explicit `version`. Version bumps land as separate `feat(deps)` PRs with rationale.
- GitHub Actions in `.github/workflows/` pin every `uses:` reference to a full commit SHA, not a tag.
- Dependabot ([`.github/dependabot.yml`](./.github/dependabot.yml)) monitors GitHub Actions deps weekly. The nightly [`mcp-version-skew`](./.github/workflows/mcp-version-skew.yml) workflow checks every uvx-pinned MCP package against PyPI and opens (or updates) a tracking issue when a stable release drifts.
- No npm dependencies. No code signing at v0.1.0; deferred per ADR A6 (lands PR 32).
