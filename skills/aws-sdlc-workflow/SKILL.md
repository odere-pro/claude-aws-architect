---
name: aws-sdlc-workflow
description: |
  **WORKFLOW SKILL** — Drive the vibe → discovery → design → plan →
  validate procedure end-to-end. Apply the depth-escalation heuristic,
  fan out L3 specialists in parallel, and merge their outputs by the
  conflict-resolution priority rules.
version: 0.1.0
---

## When to Use

Apply this skill at the orchestrator's entry point for every user prompt that may produce SDLC artefacts (`requirements.md`, `design.md`, `tasks.md`, component contracts, diagrams). The orchestrator agent is the sole consumer; L3 specialists do not invoke this skill — they are the _targets_ of the fan-out it defines. Do not apply this skill to non-AWS prompts or to interactive clarification turns that don't produce artefacts.

Trigger conditions:

- The user has just sent a prompt and the orchestrator must decide depth (shallow vs full).
- The orchestrator is about to fan out L3 specialists and needs to know which to invoke and in what message.
- Multiple specialists have returned and the orchestrator must merge their outputs into a single response.
- A specialist disagreement surfaced during merge and the orchestrator must apply the priority rules.
- A mid-turn user clarification has shifted the prompt's classification and the orchestrator must re-evaluate depth.

## Procedure

1. **Classify the prompt depth.** Apply the escalation heuristic in `references/phases.md` in the listed order: explicit override → SDLC-artefact intent → verb-of-creation → verb-of-inquiry → default. The heuristic is content-classified, not length-classified; a one-line prompt naming "design" still escalates to full depth.
2. **Pick the phase.** Vibe (sub-second routing), discovery (`requirements.md`), design (`design.md` + contracts + diagrams), plan (`tasks.md`), validate (lint passes). At v0.1.0 each phase invokes exactly one specialist; the single-message multi-`Agent`-call rule (step 3 below) is in place and becomes load-bearing when v0.2 splits the implementation specialist into three.
3. **Fan out specialists in parallel.** When depth is full, invoke all eligible specialists in a _single message with multiple `Agent` tool calls_. Sequential specialist invocations are a defect — they defeat the fan-out budget and slow the user-visible response. Detail in `references/parallel-fanout.md`.
4. **Merge specialist outputs.** Apply the conflict-resolution priority rules in order: security correctness → factual correctness → cost ceiling → architecture convergence → recency. Detail in `references/merge-rules.md`.
5. **Surface unresolved conflicts.** Disagreements that the priority rules cannot resolve appear in the merged response under `## Open Questions`. The orchestrator does not silently pick a side; the user resolves.
6. **Log every conflict resolution.** Every conflict, resolved or not, becomes a `conflict_resolution` entry in the grounding ledger. The format is owned by `aws-grounding-cache`; this skill provides the _content_ (which specialists, which options, which rule fired).

## Gotchas

- **Do not run specialists sequentially when they could run in parallel.** Sequential invocation defeats the parallel-fanout budget and inflates user-visible latency. The single-message multi-`Agent`-call pattern is mandatory at full depth; if a tool result is genuinely needed by a downstream specialist, that is a sequencing edge, not a fan-out edge.
- **Do not auto-pick on a non-trivial design disagreement.** When two specialists disagree on a data store, sync vs async, regional strategy, or any other non-trivial design decision, and no priority rule applies, the merged response surfaces both options under `## Open Questions`. Silent picks erode the user's trust in the merge.
- **Do not skip the depth re-evaluation on a clarification turn.** If the user clarifies mid-conversation and the new prompt fragment matches an SDLC-artefact intent, escalate from shallow to full depth. Once at full depth, do not auto-downgrade — full → shallow only happens by explicit user signal.
- **Do not let one specialist's failure block the merge.** A specialist that times out, exhausts its MCP-call budget, or returns an empty response surfaces as a degraded marker (`grounding-deferred`, `validation-advisory`, etc., owned by `aws-mcp-routing`). The merge proceeds with the surviving specialists; the marker appears in the user-visible output.
- **Do not silently drop a degraded signal.** Every degraded marker from any specialist appears in the merged response under `## Degraded signals`. Hiding the marker turns a partial answer into a misleadingly complete-looking one.
- **Do not produce artefacts during a shallow turn.** Shallow depth answers from grounded knowledge (with citations) and does not write to `.claude/specs/<feature>/`. If the user expected artefacts, the depth heuristic mis-classified the prompt — escalate or re-prompt, do not partially write.

## Boundaries

- This skill MUST NOT issue MCP calls itself. MCP calls are issued by the specialists and routed via `aws-mcp-routing`.
- This skill MUST NOT write the spec artefacts itself. The orchestrator writes the _final assembly_ (`requirements.md`, `design.md`, `tasks.md`); the per-component contracts and diagrams are written by the solution-architect and implementation specialists.
- This skill MUST NOT define the per-specialist MCP-call budget. Budgets are properties of each specialist's declaration and are enforced by `aws-mcp-routing`.
- This skill MUST NOT pick a side on a conflict that no priority rule resolves. Unresolved conflicts always surface to the user via `## Open Questions`.
- This skill MUST NOT downgrade depth from full to shallow within the same turn. Once a specialist has been invoked at full depth, the merge proceeds; the next turn re-classifies.
- This skill MUST NOT skip the conflict log. Every resolved conflict — even those silently resolved by the priority rules — is logged via `aws-grounding-cache` so reviewers can audit the merge.

## Quality Checks

Before returning a final orchestrator response, confirm:

- The depth classification was applied per the heuristic in `references/phases.md`, in the listed order, stopping at the first matching rule.
- Full-depth invocations used a single message with multiple `Agent` tool calls; no sequential specialist invocation.
- Every specialist's output was either merged into the final response or surfaced as a degraded marker; nothing was silently dropped.
- Every disagreement appears either in `## Open Questions` or in the conflict log.
- Every degraded marker (timeout, budget exhaustion, MCP 5xx, redaction failure) appears under `## Degraded signals`.
- Conflict-resolution log entries were queued for `aws-grounding-cache` for every conflict, resolved or unresolved.
- A shallow-depth turn resulted in no artefact writes under `.claude/specs/<feature>/`. A full-depth turn resulted in the artefacts named in `references/phases.md` being present on disk — written by the appropriate specialist or by the orchestrator's final-assembly step, not by this skill itself.
