---
name: aws-kb-navigator
description: |
  **WORKFLOW SKILL** — Navigate the kb MCP server for read-only AWS
  lookup, CLI reference, SOP retrieval, comparison, onboarding, and
  recommend / next-step / related-topic flows. Stateless per turn;
  never writes spec artefacts.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent must answer a read-only AWS knowledge question that does not produce SDLC artefacts. Use it when the user asks "what is X", "show me the CLI for X", "compare A vs B", "onboard me to X", "what should I learn next about X", or "is X available in region Y". Do not apply this skill when the prompt names an SDLC artefact (requirements, design, tasks, threat model, ROM); route those to the orchestrator's full-depth path instead.

Trigger conditions:

- The agent must answer a factual AWS question that maps to a documentation page (service overview, capability, quota, ARN shape, region availability, API verb).
- The agent must surface an AWS CLI command reference or a recipe-style SOP for a stated task.
- The agent must compare two AWS services or two configurations of the same service on a stated dimension.
- The agent must produce an onboarding pointer for a service or a learning track around a topic.
- The agent must recommend related or next-step topics tied to a previous lookup recorded in the grounding ledger.
- The previous KB call timed out, returned 5xx, or exhausted the 6-call budget — a degraded-mode decision is required.

## Procedure

1. **Classify intent.** Read the user prompt and any explicit flag (`--cli`, `--compare`, `--onboard`, `--next`, `--deep`). Choose one of the six intents in `references/intents.md`: `lookup`, `cli`, `compare`, `onboard`, `next`, `region-q`. Default when no flag fires and the prompt is a verb-of-inquiry: `lookup`.
2. **Pick the narrowest KB tool.** Apply the `aws-mcp-routing` skill against the chosen intent's tool sequence. The intent → tool map is in `references/intents.md`. Use the short server key `kb` exclusively; never call other servers from this skill.
3. **Cache pre-check.** For every planned `kb` call, query `aws-grounding-cache` first. A `cached-fresh` hit short-circuits the live call and reuses its citation. A `cached-stale` or `missing` entry proceeds to the live call.
4. **Issue the call within the per-call timeout** declared by `kb` in `.mcp.json`. Decrement the per-turn budget on every issued call. The per-turn budget is **6 KB calls**. The seventh required call triggers `budget-exhausted` and returns control to the agent's caller.
5. **Persist to the ledger** via `aws-grounding-cache`. TTL classes by intent: `immutable` for service-overview and CLI-reference reads, `region` for `list_regions` / `get_regional_availability`, `api-shape` for SOP retrievals from `retrieve_agent_sop`. Apply the redaction policy on insert; on a redaction failure abort the write and emit `redaction-failed`.
6. **Assemble the response** under the fixed five-section template enforced by `aws-kb-response.instructions.md`: a one- or two-sentence Answer, exactly one of (3–7 bullets OR a short code/CLI block), a Citations line carrying the `<server>:<short-key>` references, an up-to-five-item Related list, and an up-to-three-item Next list. Default ceiling is 250 words; `--deep` lifts it to 600.
7. **Surface degraded markers** when emitted. `grounding-deferred`, `budget-exhausted`, and `redaction-failed` are returned to the agent's caller verbatim and never absorbed.

## Gotchas

- **Do not mix lookup with SDLC mode.** If the prompt names an SDLC artefact (`requirements`, `design`, `tasks`, `runbook`, `threat-model`, `ROM`) or a verb-of-creation (`design`, `architect`, `build`, `plan`), this skill must short-circuit and tell the caller to route to `/aws` instead. Mixing the modes pollutes the per-feature spec directory and the grounding ledger.
- **Do not exceed the 6 KB-call budget.** The seventh call emits `budget-exhausted`. Re-prompt narrower; never silently truncate output.
- **Do not call any MCP server other than `kb`.** This skill is KB-only. Touching `iac`, `cost`, `sec`, `iam`, or `cw` is a contract violation and breaks the budget accounting in the routing skill.
- **Do not write spec artefacts.** This skill is stateless; the caller agent does not write to `.claude/specs/<feature>/` under any circumstance. The grounding-ledger write through the cache skill is durable but is not a spec artefact.
- **Do not strip citations to save tokens.** The response template requires the `Citations` line. Removing it converts a grounded answer into a marketing claim and trips `aws-spec-grounding`.
- **Do not invent recommendations.** `Related` and `Next` lists are populated from `kb:recommend` results or from the prompt's nearest semantic neighbours found by `kb:search_documentation`. Hand-rolled topic suggestions without a ledger entry are forbidden.
- **Do not reorder the five output sections.** The fixed order (Answer → bullets/block → Citations → Related → Next) is asserted by the `aws-kb-response` rule; reordering trips the rule's body check.

## Boundaries

- This skill MUST NOT call the AWS CLI directly. AWS knowledge access is exclusively via the `kb` MCP server.
- This skill MUST NOT add or remove MCP servers from `.mcp.json`.
- This skill MUST NOT write to `.claude/specs/<feature>/`. The kb-navigator agent that owns this skill is read-only on the feature directory.
- This skill MUST NOT delegate to L3 SDLC specialists (`claude-aws-architect-discovery-agent`, `claude-aws-architect-solution-architect-agent`, `claude-aws-architect-implementation-agent`).
- This skill MUST NOT emit a response without a `Citations` line whenever any KB retrieval succeeded; if every retrieval failed, the response is a single degraded marker, not prose.
- This skill MUST NOT cache a stale region-availability answer past the `region` TTL window declared by `aws-grounding-cache`.

## Quality Checks

Before returning a response, confirm:

- The selected intent matches one of `lookup`, `cli`, `compare`, `onboard`, `next`, `region-q`.
- Every `kb` call routed through `aws-mcp-routing` and was recorded in the ledger via `aws-grounding-cache`.
- The per-turn KB-call count is ≤6; on overrun, the response carries `budget-exhausted` rather than partial prose.
- The response follows the five-section template in the listed order with no missing section.
- The response word count is ≤250 by default and ≤600 when `--deep` was passed.
- Every factual claim in the Answer or bullets carries a `<server>:<short-key>` citation in the Citations line.
- `Related` has ≤5 items, `Next` has ≤3 items, both populated from KB results rather than invented topics.
- No write occurred under `.claude/specs/<feature>/`.
- Every degraded marker emitted by the routing or cache skills was surfaced to the caller verbatim.
