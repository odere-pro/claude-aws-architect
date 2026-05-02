---
description: Run the claude-aws-architect environment health check — verifies uvx, aws CLI, AWS_PROFILE/AWS_REGION, MCP package resolution per server, sts:GetCallerIdentity, and minimum-IAM presence. Wraps scripts/doctor.sh; safe to run anytime.
argument-hint: "[--json]"
allowed-tools:
  - Bash
  - Read
---

You are running the **claude-aws-architect doctor** — an in-session environment health check.

## Inputs

- Arguments: `$ARGUMENTS` (optional `--json` flag for structured output).
- Plugin root: `${CLAUDE_PLUGIN_ROOT}` — resolves to `scripts/doctor.sh` when the scripts bundle is installed.

## Action

1. Resolve the doctor script path: `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh`.
2. If the script exists, execute it via Bash with the user-supplied arguments forwarded verbatim. The script verifies:
   - `uvx` (and underlying `uv`) is installed and on `PATH`.
   - `aws` CLI is installed and on `PATH`.
   - `AWS_PROFILE` and `AWS_REGION` are set in the environment.
   - Every stdio MCP server declared in `${CLAUDE_PLUGIN_ROOT}/.mcp.json` resolves via `uvx`.
   - `aws sts get-caller-identity` succeeds against the resolved profile.
   - The minimum IAM permission set required by the plugin's MCP servers is present.
3. If the script does not exist yet (the scripts bundle has not been installed), emit a clearly-marked notice: the script ships in a later integration step; report which environment checks the user can run manually in the meantime.

## Exit-code mapping

When the script ran:

- `0` — environment is healthy.
- `1` — a required tool (`uvx`, `aws`) is missing.
- `2` — required environment variables (`AWS_PROFILE`, `AWS_REGION`) are missing.
- `3` — at least one MCP server failed to resolve.
- `4` — `sts:GetCallerIdentity` failed (credentials, MFA, or expired session).
- `5` — minimum-IAM presence check failed.

Surface the exit code in the user-facing response. On non-zero exit, point the user at the next step (rotate credentials, set the env var, install the missing tool) instead of emitting a wall of stack output.

## JSON mode

When `--json` is in `$ARGUMENTS`, forward it to `doctor.sh --json` and pass through the structured payload verbatim. Do not paraphrase or filter the JSON; downstream tools (CI, IDE integrations, this plugin's `/aws-spec --validate`) parse it.

## Boundaries

- This command does not install missing tools. Surfacing missing-tool errors is enough; the user runs `init.sh` separately if they want install-time setup.
- This command does not modify `.mcp.json`, `${HOME}/.aws/credentials`, or any consumer file.
- This command does not invoke MCP servers. The script's job is to verify they resolve, not to call them.

## Invocation

Run the doctor script now and report its exit code plus any structured payload.
