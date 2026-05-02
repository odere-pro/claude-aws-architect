# claude-aws-architect

A Claude Code plugin for AWS Well-Architected SDLC. Designs systems on AWS — requirements, architecture, IaC, cost, security, observability — with every factual claim grounded against AWS docs via MCP.

> **Status: pre-release scaffold (v0.1.0 in development).** This README documents the v0.1.0 design intent. Sections describing commands, agents, hooks, and powers describe the target shape; not all are implemented yet. See [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md) for build status.

## Compatibility

- **Claude Code**: `>=2.0.0` (see `.claude-plugin/plugin.json#engines.claude-code`)
- **Operating systems**: macOS (zsh + brew), Linux (bash + apt-get). Windows/WSL deferred.
- **Required external tools**: `uvx`, `aws` CLI, `jq`, `d2`, `shellcheck` — all installed by `scripts/init.sh` (lands in PR 27).

## Install

> **Not yet shippable**: install scripts land in PR 27. Until then, this section describes the intended UX.

From the consuming project root:

```bash
# Clone and symlink the plugin into your project's .claude/plugins/
git clone https://github.com/odere-pro/claude-aws-architect.git ~/.claude/plugins/claude-aws-architect
~/.claude/plugins/claude-aws-architect/scripts/install.sh --symlink
~/.claude/plugins/claude-aws-architect/scripts/init.sh --aws-profile default --aws-region us-east-1
```

## Quickstart

> **Not yet shippable**: orchestrator and commands land in PRs 16–23.

```text
/aws --deep design a serverless image-processing pipeline with cost ceiling $50/month
```

The orchestrator fans out parallel specialists (discovery → solution-architect → implementation), grounds every factual claim against AWS MCP servers, and produces:

- `.claude/specs/<feature>/requirements.md`
- `.claude/specs/<feature>/design.md`
- `.claude/specs/<feature>/tasks.md`
- `.claude/specs/<feature>/contracts/<component>.md` (one per component)
- `.claude/specs/<feature>/diagrams.d2` (C4 levels 1–3 + sequence diagrams)

## Commands

| Command                                                | Purpose                                                                                                                                                                  |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `/aws <feature-prompt>`                                | L4 orchestrator entry point. Vibe-classifies depth and either answers directly (shallow) or fans out L3 specialists in parallel and merges their outputs (full).         |
| `/aws-spec <feature> [--validate \| --list \| --show]` | Read-only validator over `.claude/specs/<feature>/`. Checks frontmatter, citations, component-contract one-to-one mapping, diagram layer tags, and re-runs plugin gates. |
| `/aws-doctor [--json]`                                 | Wraps `scripts/doctor.sh`: verifies `uvx`, `aws` CLI, `AWS_PROFILE`/`AWS_REGION`, MCP package resolution, `sts:GetCallerIdentity`, and minimum-IAM presence.             |

## Powers

> Land in PR 24.

Powers are declarative bundles (MCP servers + skills + hooks + commands) for focused workflows.

| Power                           | Bundles                                                                    |
| ------------------------------- | -------------------------------------------------------------------------- |
| `claude-aws-architect-cdk`      | CDK authoring + IaC validation + Cost ROM                                  |
| `claude-aws-architect-cost`     | Cost-only workflow: pricing MCP + cost-optimization pillar skill           |
| `claude-aws-architect-security` | Security-only workflow: WAF security MCP + IAM MCP + security pillar skill |

Bedrock and IaC-foundations powers deferred to v0.2.

## Hooks

> Land in PRs 25–26.

| Hook                      | Event       | Default | Purpose                                                |
| ------------------------- | ----------- | :-----: | ------------------------------------------------------ |
| `secret-scanner`          | PreToolUse  |   yes   | Block writes containing AWS keys, tokens, private keys |
| `aws-api-write-guard`     | PreToolUse  |   yes   | Confirm AWS write-verb MCP calls                       |
| `on-cdk-write`            | PostToolUse |   no    | Surface CDK synth + Nag check nudge                    |
| `on-iam-write`            | PostToolUse |   no    | Validate IAM JSON; least-privilege heuristic           |
| `on-bedrock-prompt-write` | PostToolUse |   no    | Check guardrail/model-id binding                       |
| `aws-test-coverage`       | PostToolUse |   no    | Surface missing AWS-touching tests                     |

Opt in/out via `.claude/claude-aws-architect.local.md`.

## Rules

> Land in PR 22.

Nine file-scoped instruction rules under `rules/` raise accuracy of AWS code:

- `aws-cdk` — CDK construct/stack discipline
- `aws-iam-policy` — least-privilege bar on IAM JSON
- `aws-sdk-usage` — retries, pagination, credential providers
- `aws-bedrock-prompt` — guardrail/model-id pinning
- `aws-test` — LocalStack-vs-real-AWS bar
- `aws-docs` — audience-first headings, cite-coverage
- `aws-diagram` — D2 layer-tag taxonomy
- `aws-component-contract` — contract frontmatter + observability triple
- `aws-spec-frontmatter` — spec-doc frontmatter + grounded-by minimum

## Troubleshooting

> Land in PR 27.

```bash
~/.claude/plugins/claude-aws-architect/scripts/doctor.sh --json
```

Common failure modes are documented in [SUPPORT.md](./SUPPORT.md).

## Uninstall

> Land in PR 27.

```bash
~/.claude/plugins/claude-aws-architect/scripts/uninstall.sh
```

Never deletes `.claude/specs/`, `.claude/steering/`, or consumer-authored hooks.

## MCP server roster

Six servers ship at v0.1.0. Each `.mcp.json` key is a short identifier (chosen to fit the 64-char tool-name budget); the **Logical name** column is what the spec text and skill prompts reference.

| Key    | Logical name                | Transport | Package (uvx target)                           | Pinned version | Timeout |
| ------ | --------------------------- | --------- | ---------------------------------------------- | -------------- | ------- |
| `kb`   | `aws-knowledge`             | http      | `https://knowledge-mcp.global.api.aws`         | 0.1.0          | 30000ms |
| `iac`  | `aws-iac`                   | stdio     | `awslabs.aws-iac-mcp-server`                   | 1.0.17         | 60000ms |
| `cost` | `aws-pricing`               | stdio     | `awslabs.aws-pricing-mcp-server`               | 1.0.28         | 30000ms |
| `sec`  | `well-architected-security` | stdio     | `awslabs.well-architected-security-mcp-server` | 0.1.7          | 60000ms |
| `iam`  | `iam`                       | stdio     | `awslabs.iam-mcp-server`                       | 1.0.18         | 30000ms |
| `cw`   | `cloudwatch`                | stdio     | `awslabs.cloudwatch-mcp-server`                | 0.0.26         | 30000ms |

Version bumps land as separate `feat(deps)` PRs.

## Minimum AWS IAM

The plugin's MCP servers exercise read-only AWS APIs. The full minimum policy lands at `skills/aws-iam-skill/references/minimum-iam-policy.json` in a later PR. Until then, `ReadOnlyAccess` is sufficient for development; production deployments should scope further.

## Privacy

The plugin ships **no telemetry**. Zero data is collected, logged, or transmitted by the plugin itself. The grounding ledger at `.claude/specs/<feature>/.grounding-ledger.json` is a local, git-ignored file and is never read or transmitted by the plugin.

## Trademark notice

- This plugin is **not affiliated with, endorsed by, or sponsored by Amazon Web Services, Inc. or its affiliates.**
- "AWS", "Amazon Web Services", "Well-Architected", and the AWS service names referenced throughout the plugin are trademarks of Amazon.com, Inc. or its affiliates.
- See the official [AWS trademark guidelines](https://aws.amazon.com/trademark-guidelines/).
- "AWS" appears in the plugin name (`claude-aws-architect`) as a descriptive token denoting the cloud provider the plugin targets, not as a claim of affiliation or endorsement.

## License

[MIT](./LICENSE).

## Security

See [SECURITY.md](./SECURITY.md) for vulnerability disclosure.

## Contributing

The full execution roadmap is at [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md). Branch and commit conventions at [docs/plan/PR-CONVENTIONS.md](./docs/plan/PR-CONVENTIONS.md). Source-of-truth design doc at [docs/plan/SPEC-v4.md](./docs/plan/SPEC-v4.md).
