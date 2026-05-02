# claude-aws-architect

<p>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/odere-pro/claude-aws-architect?style=flat-square&color=blue"></a>
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

A Claude Code plugin for AWS Well-Architected SDLC. Designs systems on AWS — requirements, architecture, IaC, cost, security, observability — with every factual claim grounded against AWS docs via MCP.

> **Status: pre-release scaffold (v0.1.0 in development).** This README documents the v0.1.0 design intent. Some commands, agents, hooks, and powers are still landing — see [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md) for build status.

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

**OS:** macOS or Linux. Windows/WSL deferred. **AWS credentials:** any `AWS_PROFILE` or SSO session with `ReadOnlyAccess`-equivalent scope.

---

## Install

```text
/plugin marketplace add odere-pro/claude-aws-architect
/plugin install claude-aws-architect@odere-pro/claude-aws-architect
/aws-doctor
```

`/aws-doctor` should print all green. If it does not, fix the prerequisite it flags before continuing.

> Manual / CI / air-gapped install: see [`docs/install.md`](./docs/install.md).

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
- `.claude/specs/<feature>/diagrams.d2`

---

## Commands

| Command       | Purpose                                                                              |
| ------------- | ------------------------------------------------------------------------------------ |
| `/aws`        | L4 orchestrator. Classifies depth and either answers directly or fans out L3 agents. |
| `/aws-spec`   | Read-only validator over `.claude/specs/<feature>/`.                                 |
| `/aws-doctor` | Verifies prerequisites, MCP package resolution, and AWS credentials.                 |

If another plugin defines a colliding name, use the namespaced form `/claude-aws-architect:<command>`.

---

## Documentation

Deep dives live under [`docs/`](./docs/). Start here:

| Topic                     | Guide                                                                                                        |
| ------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Powers (workflow bundles) | [POWERS-GUIDE.md](./docs/POWERS-GUIDE.md)                                                                    |
| MCP servers (`.mcp.json`) | [MCP-SERVERS-GUIDE.md](./docs/MCP-SERVERS-GUIDE.md)                                                          |
| Validation gates          | [VALIDATION-GATES-GUIDE.md](./docs/VALIDATION-GATES-GUIDE.md)                                                |
| Manual install / CI       | [install.md](./docs/install.md)                                                                              |
| Lifecycle scripts         | [scripts.md](./docs/scripts.md)                                                                              |
| Architecture & spec       | [SPEC.md](./SPEC.md), [docs/plan/SPEC-v4.md](./docs/plan/SPEC-v4.md)                                         |
| Contributor workflow      | [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md), [docs/plan/PR-CONVENTIONS.md](./docs/plan/PR-CONVENTIONS.md) |

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
