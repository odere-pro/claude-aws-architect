---
description: Run the claude-aws-architect orchestrator on a feature prompt — vibe-classifies depth and either answers directly or fans out L3 specialists in parallel and merges their outputs.
argument-hint: <feature-prompt>
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - Agent
---

You are invoking the **claude-aws-architect orchestrator** for an AWS architecture, design, IaC, threat-model, cost-estimate, or runbook prompt.

## Inputs

- User prompt: `$ARGUMENTS`
- Per-feature directory (if continuing an existing feature): `.claude/specs/<feature>/`
- MCP servers configured by `.mcp.json` at the plugin root: `aws-knowledge`, `aws-iac`, `aws-pricing`, `well-architected-security`, `iam`, `cloudwatch`.

## Action

Delegate to the `claude-aws-architect-orchestrator-agent` subagent. The subagent owns:

- Depth classification (shallow direct-answer vs full parallel fan-out) per the depth heuristic in `aws-sdlc-workflow`.
- On full depth: a single message containing parallel `Agent` invocations of the eligible L3 specialists (`claude-aws-architect-discovery-agent`, `claude-aws-architect-solution-architect-agent`, `claude-aws-architect-implementation-agent`) followed by a merged response per the merge contract.
- On shallow depth: a citation-backed direct answer; no artefacts written.
- Surfacing every degraded marker under `## Degraded signals` and every unresolved disagreement under `## Open Questions`.
- Final-assembly writes of `.claude/specs/<feature>/{requirements,design,tasks}.md` only when the corresponding specialist returned content this turn.

## Boundaries

- This command does not bypass the orchestrator: never call MCP servers or sibling specialists directly from the command body.
- This command does not invent a feature slug. If the prompt does not name an existing feature, the orchestrator allocates a fresh slug and creates `.claude/specs/<slug>/` on first artefact write.
- This command does not write artefacts on a shallow turn.

## Override flags

- `--deep` — force full depth even when the prompt looks like a verb-of-inquiry.
- `--quick` — force shallow depth even when the prompt names an SDLC artefact.

Pass overrides through verbatim in `$ARGUMENTS`; the orchestrator parses them.

## Invocation

Invoke the subagent now with the user's prompt as the feature-prompt argument:

> Run the `claude-aws-architect-orchestrator-agent` on the following prompt: `$ARGUMENTS`
