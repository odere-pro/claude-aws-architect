---
description: List, inspect, or validate per-feature spec folders under .claude/specs/<feature>/ produced by the claude-aws-architect orchestrator. Runs deterministic and runtime gates against requirements.md, design.md, tasks.md, contracts/, and diagrams.d2.
argument-hint: "<feature> [--validate | --list | --show]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

You are running the **claude-aws-architect spec validator** against a per-feature spec folder.

## Inputs

- Arguments: `$ARGUMENTS`
- Spec root: `.claude/specs/`
- Plugin root: `${CLAUDE_PLUGIN_ROOT}` (provides `tests/gates/run-all.sh` and `tests/run-transcripts.sh`).

## Modes

The first argument is one of:

- `--list` — list every feature folder under `.claude/specs/` with the status pulled from each `requirements.md` frontmatter.
- `--show <feature>` — print the artefact inventory for one feature: which of `requirements.md`, `design.md`, `tasks.md`, `contracts/<slug>.md`, and `diagrams.d2` exist; the status of each spec doc; the citation count per artefact; the open-question count.
- `--validate <feature>` — run the deterministic and runtime gates that apply to the feature folder.

If the first argument is a feature slug with no flag, default to `--show`.

## Validate mode — actions

When `--validate` is passed:

1. **Frontmatter and citation gates.** For each of `requirements.md`, `design.md`, `tasks.md` under `.claude/specs/<feature>/`, verify the spec-frontmatter rule: required keys (`feature`, `created`, `updated`, `status`, `grounded-by`), `grounded-by` minimum count (≥1 on `requirements.md`), status values from the closed set (`draft | review | accepted | implemented`), and inline `<server>:<short-key>` citations resolving to entries in `.grounding-ledger.json`.
2. **Component-contract gates.** For every component named in `design.md`, verify a matching `contracts/<slug>.md` exists; the component-contract rule's required frontmatter (`component`, `kind`, `version`, `status`, `talks-to`, `grounded-by`) and seven canonical body sections (Purpose, Interface, Sequence, Component view, Acceptance criteria, Observability, Integration points) are present and in order; the observability triple records a concrete metric, log, and trace; integration links resolve to sibling slugs.
3. **Diagram gates.** Verify `diagrams.d2` carries every required layer tag (`c4-l1`, `c4-l2`, one `c4-l3-<container>` per L2 container, `seq-system`, `seq-component`, `seq-error`). Verify no untagged top-level nodes; no orphan nodes.
4. **Plugin gates.** Run `${CLAUDE_PLUGIN_ROOT}/tests/gates/run-all.sh` and report PASS/WARN/FAIL per gate.
5. **Transcript-replay schema gates.** Run `${CLAUDE_PLUGIN_ROOT}/tests/run-transcripts.sh` (validate-only) so the per-feature run does not regress the harness contract.

## Output

Print a structured report:

```text
feature: <slug>
status:  requirements=<status> design=<status> tasks=<status>
artefacts:
  requirements.md       (citations: N, open questions: M)
  design.md             (components: K, pillar blocks: 6/6)
  tasks.md              (...)
  contracts/<slug>.md   (...)
  diagrams.d2           (layer tags: c4-l1 c4-l2 c4-l3-* seq-system seq-component seq-error)
gates:
  PASS  <gate-id> ...
  WARN  <gate-id> ...
  FAIL  <gate-id> ...
```

Emit FAIL lines for any gate that fails; emit a non-zero summary line when at least one FAIL is present so the caller can detect failure programmatically.

## Boundaries

- This command is read-only. It does not edit, create, or delete spec artefacts.
- This command does not invoke any MCP server. All checks are deterministic over files on disk.
- This command does not invoke the orchestrator. Spec authoring belongs to `/aws`.
- This command does not modify `.grounding-ledger.json`.

## Invocation

Parse `$ARGUMENTS` and dispatch to the matching mode. Default to `--list` when no arguments are given.
