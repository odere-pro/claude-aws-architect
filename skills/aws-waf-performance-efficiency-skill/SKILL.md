---
name: aws-waf-performance-efficiency-skill
description: |
  **WORKFLOW SKILL** — Apply the AWS Well-Architected Performance
  Efficiency pillar to a design. Walk the PE design questions, surface
  anti-patterns (inappropriate compute, missing caching, undefined
  latency targets, absent load-test plan), and emit a per-feature
  PE review block.
version: 0.1.0
---

## When to Use

Apply this skill at design time, when the solution-architect agent has produced a `design.md` and per-component contracts and is composing the per-pillar review block. The implementation agent re-applies it before transitioning a contract from `accepted` to `implemented`. Do not apply this skill to runtime profiling, post-deploy capacity tuning, or live performance triage — its scope is design-time PE assessment.

Trigger conditions:

- The agent is writing the PE review block of `design.md` for a new or revised feature.
- The agent is reviewing a draft contract and needs the PE checklist applied.
- The agent is choosing a compute model (Lambda vs ECS vs Fargate vs EC2 vs Step Functions).
- The agent is verifying that latency targets (p50, p95, p99) are named and measurable.
- The agent is auditing the caching strategy (CloudFront, ElastiCache, DAX, application-tier cache).

## Procedure

1. **Walk the design questions.** Apply the questions in `references/pe-design-questions.md` to the artefact under review. A missing answer is a finding, not a passing default.
2. **Scan for anti-patterns.** Match the design against the catalogue in `references/pe-antipatterns.md`. Each match is recorded with severity and the specific evidence (file path + section).
3. **Run the checklist.** Walk `references/pe-checklist.md` end-to-end; every item is satisfied with evidence, deferred with rationale, or flagged as a gap.
4. **Verify compute selection.** For every compute component, confirm the runtime choice is justified by the workload's traffic shape (bursty, steady, batch, scheduled) and not by team-default familiarity.
5. **Verify the load-test plan.** A design without a load-test plan named (target throughput, percentile thresholds, ramp profile) is a HIGH gap — performance targets without a verification path are wishes.
6. **Emit the PE review block.** Write the block into `design.md` using `assets/pe-review.md.tmpl` as the structure: pillar header, design-question summary, anti-patterns matched, checklist outcome, and explicit gap list with severity.

## Gotchas

- **Do not pass a compute choice that names "we already use it elsewhere" as the only rationale.** Familiarity is a real organisational cost (Cost Optimization concern, not PE). The PE rationale must name the workload's traffic shape and how the chosen compute aligns: cold-start tolerance, sustained-throughput floor, concurrency burst ceiling.
- **Do not let "we'll cache later" stand in for a caching decision.** If the design names a read-heavy path without a caching layer, that is a design-time choice; the architect either places the cache (CloudFront, ElastiCache, DAX, application-tier) or documents why the read path is fast enough without one.
- **Do not collapse PE into Cost Optimization.** PE is about hitting the latency/throughput target; Cost is about the bill at that performance level. A right-sized instance class is both a PE and a Cost concern, but the framing differs: PE asks "is it fast enough", Cost asks "is the bill justified".
- **Do not auto-resolve a missing latency target with an industry default.** A defaulted SLO defeats the design conversation. If the design has not named p50/p95/p99 latency budgets per public-facing operation, the gap is recorded; the architect supplies the value.
- **Do not write the PE review block to a file other than `design.md`.** The block lives in `design.md` under the per-pillar reviews section; per-component PE concerns surface in the contract's Acceptance criteria, not as a parallel file.
- **Do not use this skill for runtime profiling.** Live performance evidence (CloudWatch latency percentiles, X-Ray trace timing, DynamoDB throttle counts) is the `cw` MCP server's surface and the post-deploy reviewer's responsibility. This skill is design-time only.

## Boundaries

- This skill MUST NOT issue MCP calls. Citations come from prior `kb`, `iac`, and `cw` calls cached in the grounding ledger.
- This skill MUST NOT write the contract files. Per-component PE findings appear in the contract's Acceptance criteria via the implementation agent; this skill emits the per-feature PE review block in `design.md`.
- This skill MUST NOT auto-fix anti-pattern matches. Each finding is surfaced; the architect decides whether to redesign, accept the trade-off (with rationale), or defer.
- This skill MUST NOT cross into other pillars. Findings that are clearly Operational Excellence, Security, Reliability, Cost, or Sustainability concerns are routed to the corresponding pillar skill.
- This skill MUST NOT silently pass a missing latency target, missing load-test plan, or unjustified compute choice as "deferred". Missing PE discipline is a finding; deferral requires an explicit time-bounded rationale paragraph.
- This skill MUST NOT validate the runtime presence of measured latency or actual throughput. Whether the deployed system meets the target is a runtime check, not a design-time check.

## Quality Checks

Before returning a PE review decision, confirm:

- Every question in `references/pe-design-questions.md` was applied to the artefact and has either an answer (cited or rationalised) or a recorded gap.
- Every anti-pattern in `references/pe-antipatterns.md` was checked against the design; matches carry severity and evidence.
- Every checklist item in `references/pe-checklist.md` is either satisfied with evidence, deferred with rationale, or flagged.
- Every compute component has a workload-shape-based rationale for the runtime choice.
- Every public-facing operation has named p50, p95, p99 latency budgets and an SLI that measures each.
- A load-test plan is named for the feature: target throughput, percentile thresholds, ramp profile, success criteria.
- The PE review block in `design.md` follows the structure in `assets/pe-review.md.tmpl` and explicitly lists gaps with severity (HIGH / MEDIUM / LOW).
