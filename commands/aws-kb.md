---
description: Read-only AWS knowledge lookup — query docs, CLI reference, SOPs, comparisons, onboarding pointers, and next-step recommendations from the kb MCP server. Stateless per turn; never writes spec artefacts.
argument-hint: <query>
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Agent
---

You are invoking the **claude-aws-architect kb-navigator** for a read-only AWS knowledge lookup, CLI reference query, comparison, onboarding pointer, or "what should I learn next" recommendation.

## Inputs

- User query: `$ARGUMENTS`
- Per-feature directory (read-only, only if continuing an existing feature for ledger reuse): `.claude/specs/<feature>/`
- MCP server used: `kb` (aws-knowledge), as configured by `.mcp.json` at the plugin root.

## Action

Delegate to the `claude-aws-architect-kb-navigator-agent` subagent. The subagent owns:

- Intent classification across `lookup`, `cli`, `compare`, `onboard`, `next`, `region-q` per `references/intents.md` in the `aws-kb-navigator` skill.
- Narrow-tool selection on the `kb` MCP server via `aws-mcp-routing` and the per-turn 6-call budget.
- Cache pre-check and ledger persistence via `aws-grounding-cache` (durable side effect; no spec-artefact writes).
- Response assembly under the five-section template enforced by `aws-kb-response`: Answer → bullets-or-block → Citations → Related → Next.
- Degraded-marker propagation (`grounding-deferred`, `budget-exhausted`, `redaction-failed`) verbatim to the caller.

## Boundaries

- This command does not bypass the kb-navigator: never call MCP servers or sibling specialists directly from the command body.
- This command never writes to `.claude/specs/<feature>/` other than the grounding-ledger append owned by the cache skill, and never creates a feature directory.
- This command short-circuits when the query names an SDLC artefact (`requirements`, `design`, `tasks`, `runbook`, `threat-model`, `ROM`) or a verb-of-creation; the kb-navigator will redirect the caller to `/aws` rather than mixing modes.

## Intent flags

- `--cli <service>` — AWS CLI reference lookup; surfaces `aws <service> <verb>` reference and an optional SOP recipe.
- `--compare <a> vs <b>` — side-by-side comparison on a stated dimension.
- `--onboard <topic>` — onboarding pointer for a service or learning track around a topic.
- `--next` — recommendations tied to the most recent grounding-ledger entry.
- `--deep` — lift the default 250-word ceiling to 600 words.
- (no flag) — general `lookup` intent.

Pass flags through verbatim in `$ARGUMENTS`; the kb-navigator parses them.

## Invocation

Invoke the subagent now with the user's query as the argument:

> Run the `claude-aws-architect-kb-navigator-agent` on the following query: `$ARGUMENTS`
