# Scripts guide

Lifecycle and diagnostic scripts that ship under [`scripts/`](../scripts/). These are bash 3.2-compatible, log every action to stderr, and are idempotent unless explicitly noted.

## Why no slash commands for `install` / `init` / `uninstall`

Only [`doctor.sh`](#doctorsh) is exposed as a slash command (`/aws-doctor`). The rest are intentionally invoked from the shell:

- **`install.sh`** runs once at plugin install via the host's lifecycle. A `/aws-install` would be a no-op or worse — re-running side effects on an already-installed plugin.
- **`init.sh`** is a per-project bootstrap that should run on first plugin load in a repo. Re-running it interactively is rare; if you need a repair flow, use `/aws-doctor` to surface what's wrong and re-run `init.sh` from the shell.
- **`uninstall.sh`** is a one-shot removal action. Exposing it as a slash command risks users running it mid-session expecting cleanup while the plugin stays loaded.

Rule of thumb: lifecycle scripts (install/init/uninstall) stay invisible; only diagnostic/interactive scripts get slash commands.

## Script roster

| Script         | Stage      | Idempotent |  Has slash command  | Manifest-driven |
| -------------- | ---------- | :--------: | :-----------------: | :-------------: |
| `install.sh`   | install    |    yes     |         no          |     writes      |
| `init.sh`      | first-run  |    yes     |         no          |       no        |
| `doctor.sh`    | diagnostic |    yes     | yes (`/aws-doctor`) |       no        |
| `uninstall.sh` | removal    |    yes     |         no          | reads (reverse) |

All four exit with the codes documented in each script's header (mirrored in [`SUPPORT.md`](../SUPPORT.md)).

---

## `install.sh`

Install the plugin into a consumer project's `.claude/`.

```bash
~/.claude/plugins/claude-aws-architect/scripts/install.sh [--symlink | --copy]
```

### Modes (mutually exclusive)

| Mode        | Behaviour                                                                                                                                                                                                                               | When to use                                                                  |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `--symlink` | (default) Creates one symlink at `.claude/plugins/claude-aws-architect/` pointing at the plugin root. Updates ride on `git pull`.                                                                                                       | Day-to-day development; you want the plugin to track upstream automatically. |
| `--copy`    | Copies seven plugin trees (`commands`, `agents`, `skills`, `rules`, `hooks`, `recipes`, `templates`) into `.claude/<tree>/`. Files that already exist in the consumer tree are **never** overwritten — those slots stay consumer-owned. | Snapshot-style installs (CI, immutable consumer environments).               |

### Idempotency

- Re-running with the same mode is a no-op. No duplicate writes, no errors.
- Every created path is recorded to `.claude/.claude-aws-architect-installed.jsonl`. This is the manifest `uninstall.sh` reverses.
- Switching modes (e.g. `--symlink` → `--copy`) is **not** auto-migrated. Run `uninstall.sh` first, then re-install in the new mode.

### Flags

- `--help` / `-h` — print the script header and exit 0.

### Exit codes

| Code | Meaning                                                                                                                 |
| ---- | ----------------------------------------------------------------------------------------------------------------------- |
| 0    | OK                                                                                                                      |
| 64   | Bad arg                                                                                                                 |
| 65   | Target conflict (e.g. an existing symlink at `.claude/plugins/claude-aws-architect/` points at a different plugin root) |

---

## `init.sh`

First-run bootstrap for the consumer environment. Detects host tooling, pre-fetches every stdio MCP package declared in `.mcp.json` (so the first `/aws` invocation does not pay download latency), writes a settings template into `.claude/settings.json` if absent, and execs `doctor.sh`.

```bash
~/.claude/plugins/claude-aws-architect/scripts/init.sh \
  --profile default \
  --region us-east-1
```

### Flags

| Flag               | Effect                                                                                                         |
| ------------------ | -------------------------------------------------------------------------------------------------------------- |
| `--profile <name>` | Pre-set `AWS_PROFILE` in the settings template.                                                                |
| `--region <name>`  | Pre-set `AWS_REGION` in the settings template.                                                                 |
| `--force`          | Overwrite `.claude/settings.json` if it already exists. Without `--force`, an existing file is left untouched. |
| `--help`           | Print the script header and exit 0.                                                                            |

### Idempotency

- Re-running with the same inputs writes nothing new (verified by `gate-13` with a tempdir snapshot diff).
- MCP pre-fetch is skipped silently if `uvx` or `jq` is missing, or `.mcp.json` is absent.
- `init.sh` does **not** auto-install missing CLIs. It only reports what is missing so the user can act.

### Exit codes

Inherits from `doctor.sh` (final step). See [`doctor.sh`](#doctorsh) below.

---

## `doctor.sh`

Verify the local environment can run claude-aws-architect.

```bash
~/.claude/plugins/claude-aws-architect/scripts/doctor.sh [--json]
```

Or, inside Claude Code:

```text
/aws-doctor [--json]
```

### Checks

1. Required CLIs present: `uvx`, `jq`, `aws`.
2. Required env vars set: `AWS_PROFILE`, `AWS_REGION`.
3. Every stdio MCP server in `.mcp.json` resolves via `uvx --from <pkg> --help`.
4. `aws sts get-caller-identity` succeeds.
5. Minimum-IAM policy reference file is present.

### Flags

- `--json` — emit a single JSON object on stdout (no colour, no human lines). Suitable for CI assertions and `jq` pipelines.
- `--help` — print the script header and exit 0.

### Exit codes

| Code | Meaning                                  |
| ---- | ---------------------------------------- |
| 0    | OK                                       |
| 1    | Missing tool                             |
| 2    | Missing env                              |
| 3    | MCP package failed to resolve            |
| 4    | `sts:GetCallerIdentity` failed           |
| 5    | Minimum-IAM policy reference file absent |

Lowest code wins when multiple checks fail.

---

## `uninstall.sh`

Reverse `install.sh` by replaying the manifest in reverse.

```bash
~/.claude/plugins/claude-aws-architect/scripts/uninstall.sh [--dry-run]
```

Reads `.claude/.claude-aws-architect-installed.jsonl` and, for every recorded action, removes exactly the path it created — never anything else. Pre-existing consumer files are untouched (they were never recorded). The manifest itself is removed last.

### What is never removed

- `.claude/specs/` — spec authoring artefacts
- `.claude/steering/` — consumer steering files
- Consumer-authored hooks
- Any file not present in the manifest

### `--dry-run`

`--dry-run` prints every action without performing it. **Output is identical in line content and order to a real run** — gate-33 diffs the two streams byte-for-byte, so you can preview a removal with full confidence that the real run will not deviate.

```bash
~/.claude/plugins/claude-aws-architect/scripts/uninstall.sh --dry-run
```

### Flags

- `--dry-run` — preview the action stream; do not modify the filesystem.
- `--help` — print the script header and exit 0.

### Exit codes

| Code | Meaning |
| ---- | ------- |
| 0    | OK      |
| 64   | Bad arg |

---

## Common conventions

- **Logging** — every script logs structured `[ok] / [warn] / [info] / [err]` lines to stderr via `lib/common.sh`. Stdout is reserved for machine-readable output (`--json` etc.).
- **No network side-effects** — `init.sh` triggers MCP package downloads via `uvx`; nothing else makes outbound network calls.
- **No telemetry** — none of these scripts collect, log, or transmit usage data.
- **Bash 3.2 compatibility** — verified in CI on macOS system bash 3.2 and Linux bash 5+; see [`install-matrix.yml`](../.github/workflows/install-matrix.yml).
- **Gate coverage** — install/uninstall round-trip behaviour is enforced by gates 30–33 (clean roundtrip, dirty roundtrip, idempotency, dry-run parity).

## See also

- [`SUPPORT.md`](../SUPPORT.md) — exit-code reference and triage flowchart.
- [`README.md`](../README.md) — install + quickstart.
- [`commands/aws-doctor.md`](../commands/aws-doctor.md) — slash-command wrapper around `doctor.sh`.
