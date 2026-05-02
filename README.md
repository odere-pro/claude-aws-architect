# claude-aws-architect

<p>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/odere-pro/claude-aws-architect?style=flat-square&color=blue"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/releases"><img alt="Release" src="https://img.shields.io/github/v/release/odere-pro/claude-aws-architect?include_prereleases&style=flat-square&label=release&color=informational"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/.claude-plugin/plugin.json"><img alt="Plugin version" src="https://img.shields.io/badge/plugin-v0.1.0-orange?style=flat-square"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/.claude-plugin/plugin.json"><img alt="Claude Code engine" src="https://img.shields.io/badge/claude--code-%3E%3D2.0.0-7c3aed?style=flat-square&logo=anthropic&logoColor=white"></a>
  <a href="https://modelcontextprotocol.io"><img alt="MCP servers" src="https://img.shields.io/badge/MCP%20servers-6-2ea44f?style=flat-square"></a>
  <img alt="AWS" src="https://img.shields.io/badge/AWS-Well--Architected-FF9900?style=flat-square&logo=amazonwebservices&logoColor=white">
  <img alt="AWS CDK" src="https://img.shields.io/badge/AWS-CDK-FF9900?style=flat-square&logo=awslambda&logoColor=white">
  <img alt="D2" src="https://img.shields.io/badge/diagrams-D2-blueviolet?style=flat-square">
  <img alt="jq" src="https://img.shields.io/badge/tooling-jq-1f6feb?style=flat-square">
</p>

<p>
  <a href="https://github.com/odere-pro/claude-aws-architect/actions/workflows/gates.yml"><img alt="Gates" src="https://img.shields.io/github/actions/workflow/status/odere-pro/claude-aws-architect/gates.yml?branch=main&style=flat-square&label=gates&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/actions/workflows/install-matrix.yml"><img alt="Install matrix" src="https://img.shields.io/github/actions/workflow/status/odere-pro/claude-aws-architect/install-matrix.yml?branch=main&style=flat-square&label=install%20matrix&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/actions/workflows/mcp-version-skew.yml"><img alt="MCP version skew" src="https://img.shields.io/github/actions/workflow/status/odere-pro/claude-aws-architect/mcp-version-skew.yml?branch=main&style=flat-square&label=mcp%20version%20skew&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/.github/dependabot.yml"><img alt="Dependabot" src="https://img.shields.io/badge/dependabot-enabled-025E8C?style=flat-square&logo=dependabot&logoColor=white"></a>
</p>

A [Claude Code](https://claude.ai/code) plugin for AWS Well-Architected SDLC. Designs systems on AWS — requirements, architecture, IaC, cost, security, observability — with every factual claim grounded against AWS docs via MCP.

> **Status: pre-release scaffold (v0.1.0 in development).** This README documents the v0.1.0 design intent. Some commands, agents, hooks, and powers are still landing — see [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md) for build status.

---

## What's inside

| Layer        | Surface                                                                                                                                            | Count |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- | :---: |
| **MCP**      | `kb`, `iac`, `cost`, `sec`, `iam`, `cw` — see [mcp-servers-guide.md](./docs/mcp-servers-guide.md)                                                  |   6   |
| **Skills**   | 8 workflow + 6 WAF pillar                                                                                                                          |  14   |
| **Agents**   | 1 L4 orchestrator + 3 L3 SDLC specialists (`discovery`, `solution-architect`, `implementation`) + 1 read-only `kb-navigator`                       |   5   |
| **Commands** | `/aws`, `/aws-spec`, `/aws-doctor`, `/aws-kb`                                                                                                      |   4   |
| **Powers**   | `claude-aws-architect-{cdk,cost,security,kb,bedrock-ai}` — see [powers-guide.md](./docs/powers-guide.md)                                           |   5   |
| **Rules**    | 11 file-scoped instruction rules under `rules/`                                                                                                    |  11   |
| **Hooks**    | 2 PreToolUse default-on (`aws-secret-scanner`, `aws-api-write-guard`) + 4 PostToolUse default-off                                                  |   6   |
| **Gates**    | 18 deterministic + 9 runtime + 2 cross-platform + 4 install-safety + 1 release — see [validation-gates-guide.md](./docs/validation-gates-guide.md) |  34   |

---

## Prerequisites

Install these before running the plugin. `/aws-doctor` will fail loudly if any are missing.

| Tool         | Purpose                                      | Install                                                   |
| ------------ | -------------------------------------------- | --------------------------------------------------------- |
| Claude Code  | `>=2.0.0`                                    | [claude.com/code](https://claude.com/code)                |
| `uvx`        | Launches every stdio MCP server              | `pipx install uv` or [astral.sh/uv](https://astral.sh/uv) |
| `aws` CLI    | `sts:GetCallerIdentity` + live MCP API calls | [aws.amazon.com/cli](https://aws.amazon.com/cli/)         |
| `jq`         | `.mcp.json` introspection by hooks and gates | `brew install jq` / `apt-get install jq`                  |
| `d2`         | Renders `diagrams.d2` artefacts              | [d2lang.com](https://d2lang.com)                          |
| `shellcheck` | Required only if you run gates locally       | `brew install shellcheck` / `apt-get install shellcheck`  |

**OS:** macOS or Linux (both verified in CI via `install-matrix.yml`). Windows/WSL deferred. **AWS credentials:** any `AWS_PROFILE` or SSO session with `ReadOnlyAccess`-equivalent scope.

---

## Install

```text
/plugin marketplace add odere-pro/claude-aws-architect
/plugin install claude-aws-architect@odere-pro/claude-aws-architect
/aws-doctor
```

`/aws-doctor` should print all green. If it does not, fix the prerequisite it flags before continuing.

> Manual / CI / air-gapped install (`scripts/install.sh --symlink` or `--copy`): see [`docs/install.md`](./docs/install.md).

---

## Quickstart

```text
/aws --deep design a serverless image-processing pipeline with cost ceiling $50/month
```

The orchestrator fans out parallel specialists, grounds every factual claim against AWS MCP servers, and writes:

- `.claude/specs/<feature>/requirements.md`
- `.claude/specs/<feature>/design.md`
- `.claude/specs/<feature>/tasks.md`
- `.claude/specs/<feature>/contracts/<component>.md`
- `.claude/specs/<feature>/diagrams.d2` (C4 levels 1–3 + sequence diagrams)
- `.claude/specs/<feature>/.grounding-ledger.json` (every `<server>:<short-key>` citation)

Worked example: [`templates/examples/order-processing-pipeline/`](./templates/examples/order-processing-pipeline/) (event-driven order pipeline, four components, all WAF pillars PASS).

---

## Commands

| Command       | Purpose                                                                                                                                              |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/aws`        | L4 orchestrator. Classifies depth and either answers directly or fans out L3 agents.                                                                 |
| `/aws-spec`   | Read-only validator over `.claude/specs/<feature>/`.                                                                                                 |
| `/aws-doctor` | Verifies prerequisites, MCP package resolution, and AWS credentials.                                                                                 |
| `/aws-kb`     | Read-only knowledge-base lookup — docs, CLI reference, SOPs, comparisons, onboarding, next-step recs. See [aws-kb-guide.md](./docs/aws-kb-guide.md). |

If another plugin defines a colliding name, use the namespaced form `/claude-aws-architect:<command>`.

---

## Documentation

Deep dives live under [`docs/`](./docs/). Start here:

| Topic                         | Guide                                                                                                        |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Powers (workflow bundles)     | [powers-guide.md](./docs/powers-guide.md)                                                                    |
| Power playbooks (200/300/500) | [docs/playbooks/](./docs/playbooks/README.md)                                                                |
| KB navigator (`/aws-kb`)      | [aws-kb-guide.md](./docs/aws-kb-guide.md)                                                                    |
| MCP servers (`.mcp.json`)     | [mcp-servers-guide.md](./docs/mcp-servers-guide.md)                                                          |
| Validation gates (author)     | [validation-gates-guide.md](./docs/validation-gates-guide.md)                                                |
| Testing & drift detection     | [testing.md](./docs/testing.md)                                                                              |
| Manual install / CI           | [install.md](./docs/install.md)                                                                              |
| Lifecycle scripts             | [scripts.md](./docs/scripts.md)                                                                              |
| Architecture & spec           | [SPEC.md](./SPEC.md), [docs/plan/SPEC-v4.md](./docs/plan/SPEC-v4.md)                                         |
| Threat model                  | [docs/threat-model.md](./docs/threat-model.md)                                                               |
| Architectural decisions       | [docs/adr/](./docs/adr/) (A1–A7)                                                                             |
| Contributor workflow          | [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md), [docs/plan/PR-CONVENTIONS.md](./docs/plan/PR-CONVENTIONS.md) |

> **What's covered, what's not.** The gates above are **structural, not semantic** — file-shape, schema, lint, install-safety, and (when the transcript executor runs) routing assertions. There is **no live-model eval** in this repo today, so editing the body of a skill / agent / command / hook prompt passes CI as long as format and budget gates stay green. Treat prompt edits like a database migration: explicit pre-merge testing, explicit reviewer sign-off. Full breakdown and drift-closure roadmap in [`docs/testing.md`](./docs/testing.md).

---

## Troubleshooting

```text
/aws-doctor --json
```

Outside Claude Code:

```bash
~/.claude/plugins/claude-aws-architect/scripts/doctor.sh --json
```

Exit codes documented in [SUPPORT.md](./SUPPORT.md).

---

## Privacy

No telemetry. The plugin collects, logs, and transmits zero data. The grounding ledger at `.claude/specs/<feature>/.grounding-ledger.json` is local and git-ignored.

---

## Trademark notice

- This plugin is **not affiliated with, endorsed by, or sponsored by Amazon Web Services, Inc. or its affiliates.**
- "AWS", "Amazon Web Services", "Well-Architected", and the AWS service names referenced throughout the plugin are trademarks of Amazon.com, Inc. or its affiliates.
- See the official [AWS trademark guidelines](https://aws.amazon.com/trademark-guidelines/).
- "AWS" appears in the plugin name (`claude-aws-architect`) as a descriptive token denoting the cloud provider the plugin targets, not as a claim of affiliation or endorsement.

---

## License & security

[MIT](./LICENSE). Vulnerability disclosure: [SECURITY.md](./SECURITY.md).
