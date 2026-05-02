---
name: aws-waf-operational-excellence-skill
description: |
  **WORKFLOW SKILL** — Apply the AWS Well-Architected Operational
  Excellence pillar to a design. Walk the OE design questions, surface
  anti-patterns (missing runbooks, undefined SLOs, absent observability
  triple), and emit a per-feature OE review block.
version: 0.1.0
---

## When to Use

Apply this skill at design time, when the solution-architect agent has produced a `design.md` and per-component contracts and is composing the per-pillar review block. The implementation agent re-applies it before transitioning a contract from `accepted` to `implemented`. Do not apply this skill to non-AWS prose, runtime telemetry analysis, or post-incident reviews — its scope is design-time OE assessment.

Trigger conditions:

- The agent is writing the OE review block of `design.md` for a new or revised feature.
- The agent is reviewing a draft contract and needs the OE checklist applied.
- The agent is checking whether a runbook exists for the dominant failure mode in a contract.
- The agent is verifying that SLOs (latency budget, error rate, availability target) are defined and measurable.
- The agent is verifying the metric/log/trace observability triple in each contract.

## Procedure

1. **Walk the design questions.** Apply the questions in `references/oe-design-questions.md` to the artefact under review (`design.md`, contract, or both). Each question has a documented intent; a missing answer is a finding, not a passing default.
2. **Scan for anti-patterns.** Match the design against the catalogue in `references/oe-antipatterns.md`. Each match is recorded with severity and the specific evidence (file path + section).
3. **Run the checklist.** Walk `references/oe-checklist.md` end-to-end; every checklist item is either satisfied with evidence, deferred with rationale, or flagged as a gap.
4. **Verify the observability triple.** Cross-reference each contract's Observability section against the metric/log/trace requirement defined by the component-contract skill. A missing or placeholder triple is the OE pillar's most common gap and surfaces here, not silently.
5. **Verify the runbook.** For every contract whose `seq-error` (in `diagrams.d2`) names a non-trivial failure mode, confirm a runbook is named or linked. "We will add it later" is a gap, not a deferral.
6. **Emit the OE review block.** Write the block into `design.md` using `assets/oe-review.md.tmpl` as the structure: pillar header, design-question summary, anti-patterns matched, checklist outcome, and explicit gap list with severity.

## Gotchas

- **Do not pass a contract whose runbook is "TODO".** Runbooks are operational artefacts; their absence at acceptance time is a real defect, not a documentation lag. The OE review block surfaces the gap; the contract cannot transition to `implemented` until a runbook is named.
- **Do not let "we use CloudWatch" stand in for an observability triple.** The metric/log/trace requirement is enforced by the component-contract skill at lint time; this skill verifies that the named signals are _operationally meaningful_ (named SLO threshold, structured log fields, real propagation).
- **Do not auto-resolve a missing SLO with an industry-default value.** A defaulted SLO defeats the design conversation. If the design has not named a latency budget, error rate, or availability target, the gap is recorded; the architect supplies the value.
- **Do not collapse OE into Security or Reliability.** OE covers the _operational_ surface: runbooks, on-call alerting, change-management, deployment rollback. Encryption is Security; multi-AZ is Reliability. Routing those concerns to OE produces a duplicated review and dilutes both pillars.
- **Do not write the OE review block to a file other than `design.md`.** The block lives in `design.md` under a per-pillar heading; per-component OE concerns surface in the contract's Acceptance criteria, not as a parallel file.
- **Do not use this skill for runtime triage.** Runtime evidence (alarm history, log queries, metric data) is the `cw` MCP server's surface and the post-deploy reviewer's responsibility. This skill is design-time only.

## Boundaries

- This skill MUST NOT issue MCP calls. Citations come from prior `aws-knowledge` calls cached in the grounding ledger.
- This skill MUST NOT write the contract files. Per-component OE findings appear in the contract's Acceptance criteria via the implementation agent; this skill emits the per-feature OE review block in `design.md`.
- This skill MUST NOT auto-fix anti-pattern matches. Each finding is surfaced; the architect decides whether to redesign, accept the trade-off (with rationale), or defer.
- This skill MUST NOT cross into other pillars. Findings that are clearly Security, Reliability, Performance Efficiency, Cost, or Sustainability concerns are routed to the corresponding pillar skill, not absorbed by OE.
- This skill MUST NOT silently pass a missing runbook, missing SLO, or empty observability triple as "deferred". Missing operational discipline is a finding; deferral requires an explicit rationale paragraph in the OE review block.
- This skill MUST NOT validate the runtime presence of dashboards or alarms. Whether the deployed system actually emits the named signals is a runtime check, not a design-time check.

## Quality Checks

Before returning an OE review decision, confirm:

- Every question in `references/oe-design-questions.md` was applied to the artefact under review and has either an answer (cited or rationalised) or a recorded gap.
- Every anti-pattern in `references/oe-antipatterns.md` was checked against the design; matches carry severity and evidence.
- Every checklist item in `references/oe-checklist.md` is either satisfied with evidence, deferred with rationale, or flagged.
- Every contract's Observability section was checked: metric/log/trace are present, named, and operationally meaningful — not "TBD" or "TODO".
- Every contract whose `seq-error` names a failure mode has a runbook named or linked.
- The OE review block in `design.md` follows the structure in `assets/oe-review.md.tmpl` and explicitly lists gaps with severity (HIGH / MEDIUM / LOW).
