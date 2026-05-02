---
name: aws-waf-security-skill
description: |
  **WORKFLOW SKILL** — Apply the AWS Well-Architected Security pillar to
  a design. Walk the Security design questions, surface anti-patterns
  (least-privilege violations, encryption gaps, identity-perimeter
  weaknesses, incident-response gaps), and emit a per-feature Security
  review block.
version: 0.1.0
---

## When to Use

Apply this skill at design time, when the solution-architect agent has produced a `design.md` and per-component contracts and is composing the per-pillar review block. The implementation agent re-applies it before transitioning a contract from `accepted` to `implemented`. Do not apply this skill to runtime incident triage or live forensic analysis — its scope is design-time Security assessment.

Trigger conditions:

- The agent is writing the Security review block of `design.md` for a new or revised feature.
- The agent is reviewing a draft contract and needs the Security checklist applied.
- The agent is checking IAM least-privilege on a role or policy.
- The agent is verifying encryption at rest and in transit on a stateful component.
- The agent is auditing the identity perimeter (public access defaults, network exposure, secrets storage).

## Procedure

1. **Walk the design questions.** Apply the questions in `references/sec-design-questions.md` to the artefact under review. A missing answer is a finding, not a passing default.
2. **Scan for anti-patterns.** Match the design against the catalogue in `references/sec-antipatterns.md`. Each match is recorded with severity and the specific evidence (file path + section).
3. **Run the checklist.** Walk `references/sec-checklist.md` end-to-end; every item is satisfied with evidence, deferred with rationale, or flagged as a gap.
4. **Verify least-privilege.** For every IAM role/policy in the design, confirm the action set is the minimum needed. Wildcard actions (`*`, `s3:*`) at acceptance time are a HIGH gap unless explicitly justified.
5. **Verify encryption posture.** For every stateful component (S3, DynamoDB, RDS, Aurora, Secrets Manager, KMS), confirm encryption at rest is named (default-managed key vs customer-managed key) and encryption in transit is named (TLS minimum version).
6. **Emit the Security review block.** Write the block into `design.md` using `assets/sec-review.md.tmpl` as the structure: pillar header, design-question summary, anti-patterns matched, checklist outcome, and explicit gap list with severity.

## Gotchas

- **Do not pass a contract whose IAM policy uses `Action: "*"`.** Wildcard actions at acceptance time are a HIGH gap. Justified wildcards (e.g., a security-tooling role that genuinely needs broad read) require an explicit rationale paragraph in the Security review block.
- **Do not let "encryption is on by default" stand in for an encryption decision.** Default-managed keys versus customer-managed keys is a real choice (key-rotation control, cross-account access, regulatory posture); the design must name which and why.
- **Do not collapse Security into Operational Excellence.** OE covers runbooks and on-call for _operational_ incidents; Security covers _prevention_: least-privilege, encryption, identity perimeter, secrets storage. An incident-response runbook is OE; the threat model is Security.
- **Do not auto-resolve a missing threat model with "we'll do one later".** The threat model (or at least an itemised risk list) is a design-time deliverable. A contract whose Security review block has no threat model is a HIGH gap; "later" requires a time-bounded deferral.
- **Do not write the Security review block to a file other than `design.md`.** The block lives in `design.md` under the per-pillar reviews section; per-component Security findings surface in the contract's Acceptance criteria, not as a parallel file.
- **Do not use this skill for runtime forensics.** Live incident analysis (GuardDuty findings, Security Hub triage, log forensics) is the `sec` MCP server's surface and the post-incident reviewer's responsibility. This skill is design-time only.

## Boundaries

- This skill MUST NOT issue MCP calls. Citations come from prior `sec`, `iam`, and `aws-knowledge` calls cached in the grounding ledger.
- This skill MUST NOT write the contract files. Per-component Security findings appear in the contract's Acceptance criteria via the implementation agent; this skill emits the per-feature Security review block in `design.md`.
- This skill MUST NOT auto-fix anti-pattern matches. Each finding is surfaced; the architect decides whether to redesign, accept the trade-off (with rationale), or defer.
- This skill MUST NOT cross into other pillars. Findings that are clearly Operational Excellence, Reliability, Performance Efficiency, Cost, or Sustainability concerns are routed to the corresponding pillar skill.
- This skill MUST NOT silently pass a missing threat model, wildcard IAM action, or unencrypted-at-rest stateful component as "deferred". Missing security controls are findings; deferral requires an explicit time-bounded rationale paragraph.
- This skill MUST NOT validate the runtime presence of GuardDuty, Security Hub, or any detective control. Whether the deployed system actually emits findings is a runtime check, not a design-time check.

## Quality Checks

Before returning a Security review decision, confirm:

- Every question in `references/sec-design-questions.md` was applied to the artefact and has either an answer (cited or rationalised) or a recorded gap.
- Every anti-pattern in `references/sec-antipatterns.md` was checked against the design; matches carry severity and evidence.
- Every checklist item in `references/sec-checklist.md` is either satisfied with evidence, deferred with rationale, or flagged.
- Every IAM role/policy in the design has a minimum-privilege analysis recorded.
- Every stateful component has encryption-at-rest (key choice named) and encryption-in-transit (TLS version named) recorded.
- A threat model (or itemised risk list with mitigation per risk) exists for the feature.
- The Security review block in `design.md` follows the structure in `assets/sec-review.md.tmpl` and explicitly lists gaps with severity (HIGH / MEDIUM / LOW).
