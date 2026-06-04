# CLAUDE.md — entry-point notes for claude-aws-architect

This file is loaded into every Claude Code session opened from the
plugin's own repository. It exists to satisfy SPEC-v4 §H2 — the
plugin's repo points back at its own `/aws` command and its own
spec — so the plugin can be developed, dogfooded, and tested
inside Claude Code without external scaffolding.

## Plugin entry point

- Run `/aws` in any Claude Code session to invoke the
  Well-Architected SDLC orchestrator. The command lives at
  `commands/aws.md` and routes by the §5.6 depth-classification
  rules in [SPEC.md](./SPEC.md) and [docs/plan/SPEC-v4.md](./docs/plan/SPEC-v4.md).
- Run `/aws-spec <feature>` to validate an existing spec under
  `.claude/specs/<feature>/` against §11.A and §11.B gates.
- Run `/aws-doctor` to verify the host has the required CLIs
  (`uvx`, `jq`, `aws`) and that every MCP server in `.mcp.json`
  resolves.

## Self-dogfood

- The plugin's own meta-spec lives under
  `.claude/specs/claude-aws-architect/` per SPEC-v4 §H1; that
  directory is the release-dogfood acceptance artefact for the
  v0.1.0 tag (§11.E gate 34, §13.G).
- The canonical executable example lives under
  `templates/examples/order-processing-pipeline/` per §H5; that
  directory is the read-only reference §11 gates point at for any
  consumer asking what a populated spec looks like.
- The `aws-secret-scanner` and `aws-api-write-guard` PreToolUse hooks
  default-on; both are wired in `hooks/hooks.json` and apply
  inside this repo as well as in any consumer project.

## Where the spec lives

- [SPEC.md](./SPEC.md) — the canonical plugin spec, kept short.
- [docs/plan/SPEC-v4.md](./docs/plan/SPEC-v4.md) — the full v4
  declarative spec; sections 0–18.
- [docs/plan/PR-PLAN.md](./docs/plan/PR-PLAN.md) — the 33-PR
  execution roadmap with dependencies and parallel-safe flags.
- [docs/plan/PR-CONVENTIONS.md](./docs/plan/PR-CONVENTIONS.md) —
  branch naming, commit format, merge strategy.
- [docs/adr/](./docs/adr/) — architectural decision records A1–A7.

## House rules in this repo

- Every commit follows the `<type>(<scope>): <summary>` format
  documented in `docs/plan/PR-CONVENTIONS.md`.
- Every PR matches one row in `docs/plan/PR-PLAN.md` and lists the
  §11 gates it makes pass.
- Markdown files run through `prettier --check` and
  `markdownlint-cli2` (gate 14); shellscripts run through
  `shellcheck -x` (gate 4). Both are checked in CI and locally via
  `bash tests/gates/run-all.sh`.

## Naming policy for shipped artefacts

To avoid name collisions when the plugin is installed alongside other
plugins or a user's global `~/.claude/` config:

- **Slash commands** (`commands/*.md`): `aws` or `aws-<topic>`. Claude
  Code namespaces these as `claude-aws-architect:<command>` at runtime;
  the `aws-` filename prefix is the disambiguator when the user invokes
  by short name.
- **Skills** (`skills/<dir>/`): `aws-` or `aws-waf-` prefix on the
  directory name. Same runtime-namespace rationale as commands.
- **Agents** (`agents/*.md`): `claude-aws-architect-<role>-agent.md`.
  Heavy prefix is intentional — agent IDs surface in transcripts and
  the longer name keeps them unambiguous in a multi-plugin session.
- **Rules** (`rules/*.instructions.md`): `aws-` prefix.
- **Recipes** (`recipes/*.recipe.json`): `claude-aws-architect-` prefix.
- **Hooks** (`hooks/hooks.json` `name` field AND the matching
  `hooks/scripts/*.sh` filename): `aws-` prefix on both. The `name`
  field and the script filename **must match** so log lines are
  greppable.
- **Lifecycle scripts** (`scripts/install.sh`, `init.sh`, `doctor.sh`,
  `uninstall.sh`): keep conventional names. They are plugin-internal,
  called via absolute path under `${CLAUDE_PLUGIN_ROOT}/scripts/`, and
  never shadow another plugin's filesystem because each plugin lives
  in its own directory tree.

When adding a new shipped artefact, match the prefix discipline above.

## What this file is not

- Not a substitute for `SPEC.md` or `docs/plan/SPEC-v4.md`. It is
  an entry-point pointer per §H2; deeper guidance lives in those
  files.
- Not a configuration file. Consumer-local overrides go in
  `.claude/claude-aws-architect.local.md` (gitignored per §H4).
