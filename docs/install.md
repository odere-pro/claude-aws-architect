# Install guide

Three install paths, in order of preference.

| Path                                         | When to use                                                                      | Updates          | Removal                |
| -------------------------------------------- | -------------------------------------------------------------------------------- | ---------------- | ---------------------- |
| **1. Claude Code marketplace** _(preferred)_ | Day-to-day — interactive sessions, individuals, small teams.                     | `/plugin update` | `/plugin uninstall`    |
| 2. Manual symlink                            | You want the plugin to track upstream `main` automatically via `git pull`.       | `git pull`       | `scripts/uninstall.sh` |
| 3. Manual copy                               | CI runners, air-gapped environments, immutable consumer trees, pinned snapshots. | re-install       | `scripts/uninstall.sh` |

All three converge on the same end state — the marketplace path just hides the plumbing.

---

## 1. Marketplace install (preferred)

The Claude Code plugin marketplace is the recommended distribution channel. It handles registry, version resolution, updates, and clean removal natively.

### One-time setup

In any Claude Code session:

```text
/plugin marketplace add odere-pro/claude-aws-architect
```

This registers this repo as a marketplace source. You only run it once per host.

### Install

```text
/plugin install claude-aws-architect@odere-pro/claude-aws-architect
```

Claude Code resolves the latest tagged release, fetches the plugin tree, and links it into your environment.

### Verify

```text
/aws-doctor
```

`/aws-doctor` runs the same checks as `scripts/doctor.sh`: required CLIs (`uvx`, `jq`, `aws`), env vars (`AWS_PROFILE`, `AWS_REGION`), MCP server resolution, `sts:GetCallerIdentity`, and the minimum-IAM policy reference.

If any check fails, see [`SUPPORT.md`](../SUPPORT.md) for the exit-code triage flowchart.

### First run

```text
/aws --deep design a serverless image-processing pipeline with cost ceiling $50/month
```

The L4 orchestrator will depth-classify the prompt, fan out L3 specialists, and produce the spec set under `.claude/specs/<feature>/`.

### Update

```text
/plugin update claude-aws-architect
```

### Uninstall

```text
/plugin uninstall claude-aws-architect
```

Removes the plugin via the marketplace's own teardown. The plugin's own `uninstall.sh` runs as part of this lifecycle and replays the manifest in reverse — `.claude/specs/`, `.claude/steering/`, and consumer-authored hooks are never touched.

> **Note.** The marketplace listing is tracked in [ADR-0006](./adr/ADR-0006-license-and-distribution.md) §15.3. If the listing isn't yet live for your Claude Code build, fall back to path 2 or 3 below.

---

## 2. Manual symlink install

Use when you want the plugin to track upstream `main` via plain `git pull`.

```bash
git clone https://github.com/odere-pro/claude-aws-architect.git \
  ~/.claude/plugins/claude-aws-architect

~/.claude/plugins/claude-aws-architect/scripts/install.sh --symlink

~/.claude/plugins/claude-aws-architect/scripts/init.sh \
  --profile default \
  --region us-east-1
```

- `install.sh --symlink` (default) creates one symlink at `.claude/plugins/claude-aws-architect/` pointing at the cloned repo.
- `init.sh` detects host CLIs, pre-fetches every stdio MCP package, writes a `settings.json` template, and execs `doctor.sh`.

To update: `cd ~/.claude/plugins/claude-aws-architect && git pull`.

Full script reference: [`docs/scripts.md`](./scripts.md).

---

## 3. Manual copy install

Use for CI runners, air-gapped environments, or anywhere you want a snapshot rather than a live link.

```bash
git clone https://github.com/odere-pro/claude-aws-architect.git \
  ~/.claude/plugins/claude-aws-architect

~/.claude/plugins/claude-aws-architect/scripts/install.sh --copy

~/.claude/plugins/claude-aws-architect/scripts/init.sh \
  --profile default \
  --region us-east-1
```

- `install.sh --copy` copies the seven plugin trees (`commands`, `agents`, `skills`, `rules`, `hooks`, `recipes`, `templates`) into `.claude/<tree>/`. Files that already exist in the consumer tree are **never** overwritten — those slots stay consumer-owned.
- Updates require running `uninstall.sh` then re-installing.

---

## Prerequisites

Required on `$PATH`:

- `uvx` (Astral) — runs the stdio MCP servers
- `aws` CLI — for `sts:GetCallerIdentity` checks
- `jq` — JSON manipulation
- `d2` — diagram rendering (used by the `aws-layered-diagram` skill)
- `shellcheck` — only required to run the gate suite locally

`init.sh` does **not** auto-install these. It detects what's missing and prints a remediation hint per tool.

Required env (read by `doctor.sh`):

- `AWS_PROFILE`
- `AWS_REGION`

---

## Uninstall (any path)

```bash
~/.claude/plugins/claude-aws-architect/scripts/uninstall.sh --dry-run    # preview
~/.claude/plugins/claude-aws-architect/scripts/uninstall.sh              # execute
```

`--dry-run` output is byte-identical to the real run (gate-33 contract). Pre-existing consumer files, `.claude/specs/`, `.claude/steering/`, and consumer-authored hooks are never touched.

When the marketplace flow takes over removal, it invokes `uninstall.sh` for you with the same guarantees.

---

## See also

- [`README.md`](../README.md) — overview, commands, hooks, gates.
- [`docs/scripts.md`](./scripts.md) — full per-script flag/exit-code reference.
- [`SUPPORT.md`](../SUPPORT.md) — doctor exit-code triage.
