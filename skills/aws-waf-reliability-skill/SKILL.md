---
name: aws-waf-reliability-skill
description: |
  **WORKFLOW SKILL** — Apply the AWS Well-Architected Reliability
  pillar to a design. Walk the Reliability design questions, surface
  anti-patterns (single-AZ, missing retries, undefined recovery
  objectives, absent failure-mode analysis), and emit a per-feature
  Reliability review block.
version: 0.1.0
---

## When to Use

Apply this skill at design time, when the solution-architect agent has produced a `design.md` and per-component contracts and is composing the per-pillar review block. The implementation agent re-applies it before transitioning a contract from `accepted` to `implemented`. Do not apply this skill to runtime incident triage, live failover execution, or chaos-experiment runs — its scope is design-time Reliability assessment.

Trigger conditions:

- The agent is writing the Reliability review block of `design.md` for a new or revised feature.
- The agent is reviewing a draft contract and needs the Reliability checklist applied.
- The agent is verifying recovery objectives (RTO and RPO) are named, measurable, and consistent with the chosen DR strategy.
- The agent is checking multi-AZ posture, failover paths, or read-replica configuration on stateful components.
- The agent is verifying retry, timeout, idempotency, and circuit-breaker policies on every cross-service call.
- The agent is auditing dependency mapping, quota headroom, and failure-mode analysis for the feature.

## Procedure

1. **Walk the design questions.** Apply the questions in `references/rel-design-questions.md` to the artefact under review. A missing answer is a finding, not a passing default.
2. **Scan for anti-patterns.** Match the design against the catalogue in `references/rel-antipatterns.md`. Each match is recorded with severity and the specific evidence (file path + section).
3. **Run the checklist.** Walk `references/rel-checklist.md` end-to-end; every item is satisfied with evidence, deferred with rationale, or flagged as a gap.
4. **Verify recovery objectives.** For every component holding state or serving a critical path, confirm RTO and RPO are named with units (minutes/hours, bytes/transactions). The chosen DR strategy (backup-restore, pilot light, warm standby, multi-site active-active) must be consistent with those numbers; mismatches are HIGH gaps.
5. **Verify multi-AZ and failover.** For every stateful or singleton component, confirm AZ posture is named (single-AZ with rationale, multi-AZ active-passive, multi-AZ active-active) and the failover trigger and detection mechanism are documented.
6. **Verify retry, timeout, idempotency.** For every cross-service call (HTTP, SQS, SNS, EventBridge, Step Functions, downstream SaaS), confirm a timeout, a retry policy with bounded attempts and jitter, and an idempotency strategy. Unbounded retries, naked timeouts, and non-idempotent retried writes are HIGH gaps.
7. **Emit the Reliability review block.** Write the block into `design.md` using `assets/rel-review.md.tmpl` as the structure: pillar header, design-question summary, anti-patterns matched, FMA outcome, checklist outcome, and explicit gap list with severity.

## Gotchas

- **Do not pass a contract whose RTO or RPO is "TBD".** Recovery objectives are the contract between the business and the architecture; their absence at acceptance time is a HIGH gap. "Best effort" is not an objective; "≤ 15 minutes RTO, ≤ 5 minutes RPO" is.
- **Do not equate "we use AWS managed services" with reliability.** Managed services have their own SLAs, quotas, and partial-failure modes. The design names the relevant SLA (e.g. RDS Multi-AZ 99.95%), the relevant quota (e.g. Lambda concurrency, DynamoDB partition throughput), and the headroom assumption.
- **Do not let a single-AZ deployment stand without rationale.** Single-AZ is a legitimate choice for non-production or cost-bounded workloads, but it must be named as a deliberate trade-off with a deferral or acceptance, not a silent default. A production stateful component on a single AZ without rationale is a HIGH gap.
- **Do not collapse Reliability into Operational Excellence.** OE covers the _operational_ surface (runbooks, on-call, dashboards); Reliability covers the _engineered_ recovery posture (RTO/RPO, multi-AZ, retries, idempotency, FMA). A runbook is OE; the failure-mode analysis the runbook responds to is Reliability.
- **Do not auto-resolve a missing FMA with "we'll think about failures during implementation".** Failure-mode analysis is a design-time deliverable. A contract whose Reliability review block has no FMA is a HIGH gap; "later" requires a time-bounded deferral.
- **Do not write the Reliability review block to a file other than `design.md`.** The block lives in `design.md` under the per-pillar reviews section; per-component Reliability findings surface in the contract's Acceptance criteria, not as a parallel file.
- **Do not use this skill for runtime incident analysis.** Live failover decisions, chaos-experiment execution, and post-incident reviews are runtime concerns owned by the on-call and the post-incident reviewer. This skill is design-time only.

## Boundaries

- This skill MUST NOT issue MCP calls. Citations come from prior `aws-knowledge`, `cw`, and `iac` calls cached in the grounding ledger.
- This skill MUST NOT write the contract files. Per-component Reliability findings appear in the contract's Acceptance criteria via the implementation agent; this skill emits the per-feature Reliability review block in `design.md`.
- This skill MUST NOT auto-fix anti-pattern matches. Each finding is surfaced; the architect decides whether to redesign, accept the trade-off (with rationale), or defer.
- This skill MUST NOT cross into other pillars. Findings that are clearly Operational Excellence, Security, Performance Efficiency, Cost, or Sustainability concerns are routed to the corresponding pillar skill.
- This skill MUST NOT silently pass a missing RTO/RPO, missing FMA, or untreated single-AZ stateful component as "deferred". Missing reliability discipline is a finding; deferral requires an explicit time-bounded rationale paragraph.
- This skill MUST NOT validate the runtime presence of failover, alarms, or recovery automation. Whether the deployed system actually fails over is a runtime check, not a design-time check.

## Quality Checks

Before returning a Reliability review decision, confirm:

- Every question in `references/rel-design-questions.md` was applied to the artefact and has either an answer (cited or rationalised) or a recorded gap.
- Every anti-pattern in `references/rel-antipatterns.md` was checked against the design; matches carry severity and evidence.
- Every checklist item in `references/rel-checklist.md` is either satisfied with evidence, deferred with rationale, or flagged.
- Every component on a critical path has RTO and RPO named with units, and the chosen DR strategy is consistent with those numbers.
- Every stateful or singleton component has AZ posture named (with rationale for single-AZ where applicable) and a failover trigger documented.
- Every cross-service call has timeout, retry policy with jitter and bounded attempts, and idempotency strategy named.
- A failure-mode analysis (FMA) exists for the feature: top failure modes itemised with detection, blast radius, and mitigation.
- The Reliability review block in `design.md` follows the structure in `assets/rel-review.md.tmpl` and explicitly lists gaps with severity (HIGH / MEDIUM / LOW).
