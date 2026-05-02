# claude-aws-architect

A [Claude Code](https://claude.ai/code) plugin for AWS Well-Architected SDLC. Designs systems on AWS — requirements, architecture, IaC, cost, security, observability — with every factual claim grounded against AWS docs via MCP.

<p>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/odere-pro/claude-aws-architect?style=flat-square&color=blue"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/releases"><img alt="Release" src="https://img.shields.io/github/v/release/odere-pro/claude-aws-architect?include_prereleases&style=flat-square&label=release&color=informational"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/.claude-plugin/plugin.json"><img alt="Plugin version" src="https://img.shields.io/badge/plugin-v0.1.0-orange?style=flat-square"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/.claude-plugin/plugin.json"><img alt="Claude Code engine" src="https://img.shields.io/badge/claude--code-%3E%3D2.0.0-7c3aed?style=flat-square&logo=anthropic&logoColor=white"></a>
  <a href="https://modelcontextprotocol.io"><img alt="MCP servers" src="https://img.shields.io/badge/MCP%20servers-6-2ea44f?style=flat-square"></a>
</p>

<p>
  <a href="https://github.com/odere-pro/claude-aws-architect/actions/workflows/gates.yml"><img alt="Gates" src="https://img.shields.io/github/actions/workflow/status/odere-pro/claude-aws-architect/gates.yml?branch=main&style=flat-square&label=gates&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/actions/workflows/install-matrix.yml"><img alt="Install matrix" src="https://img.shields.io/github/actions/workflow/status/odere-pro/claude-aws-architect/install-matrix.yml?branch=main&style=flat-square&label=install%20matrix&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/actions/workflows/mcp-version-skew.yml"><img alt="MCP version skew" src="https://img.shields.io/github/actions/workflow/status/odere-pro/claude-aws-architect/mcp-version-skew.yml?branch=main&style=flat-square&label=mcp%20version%20skew&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/blob/main/.github/dependabot.yml"><img alt="Dependabot" src="https://img.shields.io/badge/dependabot-enabled-025E8C?style=flat-square&logo=dependabot&logoColor=white"></a>
</p>

<p>
  <a href="https://github.com/odere-pro/claude-aws-architect/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/odere-pro/claude-aws-architect?style=flat-square&logo=github"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/network/members"><img alt="Forks" src="https://img.shields.io/github/forks/odere-pro/claude-aws-architect?style=flat-square&logo=github"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/issues"><img alt="Open issues" src="https://img.shields.io/github/issues/odere-pro/claude-aws-architect?style=flat-square&logo=github"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/pulls"><img alt="Open PRs" src="https://img.shields.io/github/issues-pr/odere-pro/claude-aws-architect?style=flat-square&logo=github"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/odere-pro/claude-aws-architect/main?style=flat-square&logo=git&logoColor=white"></a>
  <a href="https://github.com/odere-pro/claude-aws-architect/graphs/contributors"><img alt="Contributors" src="https://img.shields.io/github/contributors/odere-pro/claude-aws-architect?style=flat-square&logo=github"></a>
</p>

<p>
  <img alt="Bash" src="https://img.shields.io/badge/Bash-3.2%2B-4EAA25?style=flat-square&logo=gnubash&logoColor=white">
  <img alt="Shell" src="https://img.shields.io/badge/language-Shell-89e051?style=flat-square&logo=gnu&logoColor=white">
  <img alt="AWS" src="https://img.shields.io/badge/AWS-Well--Architected-FF9900?style=flat-square&logo=amazonwebservices&logoColor=white">
  <img alt="AWS CDK" src="https://img.shields.io/badge/AWS-CDK-FF9900?style=flat-square&logo=awslambda&logoColor=white">
  <img alt="MCP" src="https://img.shields.io/badge/MCP-Model%20Context%20Protocol-000000?style=flat-square">
  <img alt="D2" src="https://img.shields.io/badge/diagrams-D2-blueviolet?style=flat-square">
  <img alt="jq" src="https://img.shields.io/badge/tooling-jq-1f6feb?style=flat-square">
  <img alt="shellcheck" src="https://img.shields.io/badge/lint-shellcheck-2bb24c?style=flat-square">
  <img alt="prettier" src="https://img.shields.io/badge/format-prettier-F7B93E?style=flat-square&logo=prettier&logoColor=black">
  <img alt="markdownlint" src="https://img.shields.io/badge/lint-markdownlint-023047?style=flat-square">
</p>

<p>
  <img alt="macOS" src="https://img.shields.io/badge/macOS-bash%203.2%20%26%205%2B-000000?style=flat-square&logo=apple&logoColor=white">
  <img alt="Linux" src="https://img.shields.io/badge/Linux-bash%205%2B-FCC624?style=flat-square&logo=linux&logoColor=black">
  <img alt="Windows" src="https://img.shields.io/badge/Windows-WSL%20deferred-lightgrey?style=flat-square&logo=windows&logoColor=white">
</p>

> **Status: pre-release scaffold (v0.1.0 in development).** All planned skills, agents, hooks, powers, commands, scripts, and gates are merged on `main`; release-dogfood (self-design) artefact lives at `.claude/specs/claude-aws-architect/`. Tag `v0.1.0` lands once final CI matrix is green across both `ubuntu-latest` and `macos-latest`.

## What's inside

| Layer        | Surface                                                                                                                                                                 | Count |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---: |
| **MCP**      | `kb` (aws-knowledge), `iac` (CFN/CDK validate), `cost` (pricing), `sec` (Well-Architected security), `iam`, `cw` (CloudWatch)                                           |   6   |
| **Skills**   | 6 workflow (`aws-mcp-routing`, `aws-spec-grounding`, `aws-grounding-cache`, `aws-component-contract`, `aws-layered-diagram`, `aws-sdlc-workflow`) + 6 WAF pillar skills |  12   |
| **Agents**   | 1 L4 orchestrator (`max-iterations: 3`, parallel fan-out) + 3 L3 specialists (`discovery`, `solution-architect`, `implementation`)                                      |   4   |
| **Commands** | `/aws`, `/aws-spec`, `/aws-doctor`                                                                                                                                      |   3   |
| **Powers**   | `claude-aws-architect-cdk`, `claude-aws-architect-cost`, `claude-aws-architect-security` (declarative MCP + skill + hook + command bundles)                             |   3   |
| **Rules**    | 9 file-scoped instruction rules under `rules/*.instructions.md`                                                                                                         |   9   |
| **Hooks**    | 2 PreToolUse default-on (`aws-secret-scanner`, `aws-api-write-guard`) + 4 PostToolUse default-off (CDK, IAM, Bedrock-prompt, test-coverage advisories)                  |   6   |
| **Gates**    | 18 deterministic + 9 runtime (transcript-replay) + 2 cross-platform + 4 install-safety + 1 release                                                                      |  34   |
| **Fixtures** | `vibe-shallow`, `sdlc-full-depth`, `merge-conflict`, `degraded-mcp`, `iteration-cap`                                                                                    |   5   |
| **ADRs**     | A1–A7 (architecture, contracts, MCP roster, merge contract, escalation, license, supply chain)                                                                          |   7   |

## Compatibility

- **Claude Code**: `>=2.0.0` (see [`.claude-plugin/plugin.json`](./.claude-plugin/plugin.json))
- **Operating systems**: macOS (system bash 3.2 + brew bash 5+) and Linux (bash 5+) — both verified in CI via `install-matrix.yml`. Windows/WSL deferred.
- **Required external tools**: `uvx`, `aws` CLI, `jq`, `d2`, `shellcheck` — detected (not auto-installed) by `scripts/init.sh`.

## Install

From the consuming project root:

```bash
git clone https://github.com/odere-pro/claude-aws-architect.git ~/.claude/plugins/claude-aws-architect
~/.claude/plugins/claude-aws-architect/scripts/install.sh --symlink
~/.claude/plugins/claude-aws-architect/scripts/init.sh --aws-profile default --aws-region us-east-1
```

Two install modes:

- **`--symlink`** (default) — symlinks the plugin tree into `.claude/plugins/claude-aws-architect/`. Updates ride on `git pull`.
- **`--copy`** — copies the seven plugin trees (`commands`, `agents`, `skills`, `rules`, `hooks`, `powers`, `templates`) into `.claude/<tree>/`. Snapshot-style; updates need a re-install.

Idempotent across reruns. `uninstall.sh --dry-run` lists exactly what `uninstall.sh` would remove (gate-33 byte-equality contract). Never touches `.claude/specs/`, `.claude/steering/`, or consumer-authored hooks.

## Quickstart

```text
/aws --deep design a serverless image-processing pipeline with cost ceiling $50/month
```

The L4 orchestrator depth-classifies the prompt, fans out parallel L3 specialists (≤3 concurrent calls per turn, `max-iterations: 3`), grounds every factual claim against AWS MCP servers, and produces:

- `.claude/specs/<feature>/requirements.md`
- `.claude/specs/<feature>/design.md`
- `.claude/specs/<feature>/tasks.md`
- `.claude/specs/<feature>/contracts/<component>.md` (one per component)
- `.claude/specs/<feature>/diagrams.d2` (C4 levels 1–3 + sequence diagrams)
- `.claude/specs/<feature>/.grounding-ledger.json` (every `<server>:<short-key>` citation)

Canonical worked example under [`templates/examples/order-processing-pipeline/`](./templates/examples/order-processing-pipeline/) (event-driven order pipeline, four components, all WAF pillars PASS).

## Commands

| Command                                                | Purpose                                                                                                                                                                |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/aws <feature-prompt>`                                | L4 orchestrator. Vibe-classifies depth and either answers directly (shallow) or fans out L3 specialists in parallel and merges their outputs (full) per §5.5 priority. |
| `/aws-spec <feature> [--validate \| --list \| --show]` | Read-only validator over `.claude/specs/<feature>/`: frontmatter, citations, contract one-to-one mapping, diagram layer tags, plugin gates.                            |
| `/aws-doctor [--json]`                                 | Wraps `scripts/doctor.sh`: verifies `uvx`, `aws` CLI, `AWS_PROFILE`/`AWS_REGION`, MCP package resolution, `sts:GetCallerIdentity`, and minimum-IAM presence.           |

## Powers

Declarative bundles (MCP servers + skills + hooks + commands) for focused workflows. Each is a single JSON file under [`powers/<name>.power.json`](./powers/).

| Power                           | Bundles                                                                    |
| ------------------------------- | -------------------------------------------------------------------------- |
| `claude-aws-architect-cdk`      | CDK authoring + IaC validation + Cost ROM                                  |
| `claude-aws-architect-cost`     | Cost-only workflow: pricing MCP + cost-optimization pillar skill           |
| `claude-aws-architect-security` | Security-only workflow: WAF security MCP + IAM MCP + security pillar skill |

Bedrock and IaC-foundations powers deferred to v0.2.

## Hooks

| Hook                          | Event       | Default | Purpose                                                |
| ----------------------------- | ----------- | :-----: | ------------------------------------------------------ |
| `aws-secret-scanner`          | PreToolUse  |   yes   | Block writes containing AWS keys, tokens, private keys |
| `aws-api-write-guard`         | PreToolUse  |   yes   | Confirm AWS write-verb MCP calls                       |
| `aws-on-cdk-write`            | PostToolUse |   no    | Surface CDK synth + Nag check nudge                    |
| `aws-on-iam-write`            | PostToolUse |   no    | Validate IAM JSON; least-privilege heuristic           |
| `aws-on-bedrock-prompt-write` | PostToolUse |   no    | Check guardrail / model-id binding                     |
| `aws-test-coverage`           | PostToolUse |   no    | Surface missing AWS-touching tests                     |

Opt in/out via `.claude/claude-aws-architect.local.md`.

## Rules

Nine file-scoped instruction rules under [`rules/`](./rules/) raise per-file accuracy:

- `aws-cdk` — CDK construct/stack discipline
- `aws-iam-policy` — least-privilege bar on IAM JSON
- `aws-sdk-usage` — retries, pagination, credential providers
- `aws-bedrock-prompt` — guardrail / model-id pinning
- `aws-test` — LocalStack-vs-real-AWS bar
- `aws-docs` — audience-first headings, cite-coverage
- `aws-diagram` — D2 layer-tag taxonomy
- `aws-component-contract` — contract frontmatter + observability triple
- `aws-spec-frontmatter` — spec-doc frontmatter + grounded-by minimum

## CI / CD

| Workflow               | Trigger                                                        | What it asserts                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `gates.yml`            | every push/PR; matrix Linux bash 5+ / macOS bash 3.2 / brew 5+ | Deterministic gates 1–18 + transcript-validate (gate 19 + the §11.B contract assertions for fixtures 20–27)                                            |
| `install-matrix.yml`   | push/PR touching `scripts/**`, install gates, or this workflow | End-to-end install/doctor/uninstall on `ubuntu-latest` and `macos-latest`; gates 30–33 (clean roundtrip, dirty roundtrip, idempotency, dry-run parity) |
| `mcp-version-skew.yml` | nightly `17 4 * * *` + `workflow_dispatch`                     | jq scan of every `uvx` MCP server in `.mcp.json` against PyPI JSON; idempotent issue lifecycle when drift appears                                      |
| `dependabot.yml`       | weekly Mon 06:00 UTC                                           | GitHub Actions ecosystem only at v0.1.0; grouped minor/patch with `chore(deps)` prefix                                                                 |

`actions/checkout` is SHA-pinned. Every workflow runs read-only by default; the only side effects are issue lifecycle on `mcp-version-skew.yml`.

## Validation gates

| Tier           | IDs   | Where enforced                                                  |
| -------------- | ----- | --------------------------------------------------------------- |
| Deterministic  | 1–18  | `tests/gates/run-all.sh` + `gates.yml`                          |
| Runtime        | 19–27 | `tests/run-transcripts.sh --execute` (fixture contract gates)   |
| Cross-platform | 28–29 | CI matrix on `ubuntu-latest`, `macos-latest`                    |
| Install-safety | 30–33 | `tests/gates/gate-3{0,1,2,3}-*.sh` + `install-matrix.yml`       |
| Release        | 34    | Self-design dogfood under `.claude/specs/claude-aws-architect/` |

`bash tests/gates/run-all.sh` runs every deterministic + install-safety gate locally; `bash tests/run-transcripts.sh --execute` exits 0 across all five fixtures with gates 19–27 PASS.

## Tech stack

- **Language:** POSIX shell, bash 3.2-compatible across the install/doctor/uninstall scripts and every hook.
- **Lint / format:** `shellcheck -x`, `markdownlint-cli2`, `prettier`.
- **Diagrams:** [D2](https://d2lang.com) via the `aws-layered-diagram` skill (six layer tags: `c4-l1`, `c4-l2`, `c4-l3-<container>`, `seq-system`, `seq-component`, `seq-error`).
- **MCP runtime:** stdio servers via `uvx` (Astral); HTTP server for `aws-knowledge`. All version-pinned in `.mcp.json` and timeout-configured per O2.
- **Schema validation:** `jq` for JSON; YAML frontmatter validated via the `tests/gates/gate-05-yaml-frontmatter.sh` parser.
- **AWS surface:** read-only AWS APIs via the official `awslabs.*` MCP servers; no live writes (gated by `aws-api-write-guard`).

## Troubleshooting

```bash
~/.claude/plugins/claude-aws-architect/scripts/doctor.sh --json
```

Exit codes 0/1/2/3/4/5 documented in [SUPPORT.md](./SUPPORT.md).

## Uninstall

```bash
~/.claude/plugins/claude-aws-architect/scripts/uninstall.sh
```

Replays the `.claude/.claude-aws-architect-installed.jsonl` manifest in reverse. Never deletes `.claude/specs/`, `.claude/steering/`, or consumer-authored hooks.

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

Drift is monitored nightly by [`mcp-version-skew.yml`](./.github/workflows/mcp-version-skew.yml). Version bumps land as separate `feat(deps)` commits.

## Minimum AWS IAM

The plugin's MCP servers exercise read-only AWS APIs. The full minimum policy lives at `skills/aws-iam-skill/references/minimum-iam-policy.json`. `ReadOnlyAccess` is sufficient for development; production deployments should scope further.

## Privacy

The plugin ships **no telemetry**. Zero data is collected, logged, or transmitted by the plugin itself. The grounding ledger at `.claude/specs/<feature>/.grounding-ledger.json` is local, git-ignored by default, and never read or transmitted by the plugin.

## Trademark notice

- This plugin is **not affiliated with, endorsed by, or sponsored by Amazon Web Services, Inc. or its affiliates.**
- "AWS", "Amazon Web Services", "Well-Architected", and the AWS service names referenced throughout the plugin are trademarks of Amazon.com, Inc. or its affiliates.
- See the official [AWS trademark guidelines](https://aws.amazon.com/trademark-guidelines/).
- "AWS" appears in the plugin name (`claude-aws-architect`) as a descriptive token denoting the cloud provider the plugin targets, not as a claim of affiliation or endorsement.

## License

[MIT](./LICENSE).

## Security

See [SECURITY.md](./SECURITY.md) for vulnerability disclosure. Threat model under [`docs/threat-model.md`](./docs/threat-model.md).

## Contributing

Source-of-truth design doc at [`docs/plan/SPEC-v4.md`](./docs/plan/SPEC-v4.md). Branch and commit conventions at [`docs/plan/PR-CONVENTIONS.md`](./docs/plan/PR-CONVENTIONS.md). Architectural decisions A1–A7 under [`docs/adr/`](./docs/adr/).
