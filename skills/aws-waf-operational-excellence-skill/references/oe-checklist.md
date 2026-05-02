# OE checklist

Loaded on demand by the `aws-waf-operational-excellence-skill`. End-to-end checklist for the Operational Excellence pillar at design time. Each item is satisfied with evidence, deferred with rationale, or flagged as a gap.

## How to use this checklist

For each item below:

1. Mark **PASS** with the evidence (file path + section, or citation).
2. Mark **DEFER** with a one-paragraph rationale (why this is OK to ship without satisfying).
3. Mark **GAP** when neither — the OE review block lists every GAP with severity.

The checklist is intentionally exhaustive at the cost of redundancy with `oe-design-questions.md` and `oe-antipatterns.md`. The questions are open-ended; the anti-patterns scan for known shapes; this checklist is the final pre-acceptance gate.

## Organisation

- [ ] **OEC-1.** On-call rotation or team is named.
- [ ] **OEC-2.** Escalation path is named.
- [ ] **OEC-3.** Runbook ownership is named. If a single individual, a fallback executor is documented (matches `AP-OE-15` graduated severity: LOW for organisational hygiene, HIGH only when the named individual is the sole executor).
- [ ] **OEC-4.** If the build team and on-call team are distinct, a knowledge-transfer artefact exists (runbook, recording, shadowing plan).

## Observability and signals

- [ ] **OEC-5.** Every component contract has a populated Metric subsection: name, source, threshold (where applicable).
- [ ] **OEC-6.** Every component contract has a populated Log subsection: destination, structured fields, level discipline.
- [ ] **OEC-7.** Every component contract has a populated Trace subsection: tracer, propagation, sampling rule.
- [ ] **OEC-8.** No subsection contains `TODO`, `TBD`, or unfilled `<angle-bracket>` placeholders.
- [ ] **OEC-9.** Trace propagation crosses every `c4-l2` boundary, or each break carries a documented rationale.

## SLOs and SLIs

- [ ] **OEC-10.** Latency budget (p50, p95, p99) is named per operation. Severity per `AP-OE-6`: HIGH gap for public-facing components; MEDIUM for internal. Label accordingly in the review block.
- [ ] **OEC-11.** Error-rate budget is named. Severity per `AP-OE-6`: HIGH for public-facing, MEDIUM for internal.
- [ ] **OEC-12.** Availability target is named. Severity per `AP-OE-6`: HIGH for public-facing, MEDIUM for internal.
- [ ] **OEC-13.** Each SLO has a corresponding SLI: a metric query or alarm that measures it.
- [ ] **OEC-14.** SLO dashboard URL or planned location is named.

## Failure response

- [ ] **OEC-15.** The dominant failure mode in `seq-error` has a runbook named or linked.
- [ ] **OEC-16.** Runbooks are versioned alongside code (or a documented coordination mechanism exists).
- [ ] **OEC-17.** RTO and RPO are defined for every stateful component.
- [ ] **OEC-18.** A rehearsal cadence is named (game day, table-top), or the absence is explicitly accepted with rationale.

## Deployment and change management

- [ ] **OEC-19.** Deployment is automated, or a manual deployment runbook is named.
- [ ] **OEC-20.** Rollback strategy is named, including worst-case time-to-rollback.
- [ ] **OEC-21.** Canary / progressive deployment is named for high-impact components, or the absence is explicitly accepted.
- [ ] **OEC-22.** IaC and application change coordination is documented when they share a release boundary.

## Operational telemetry and review

- [ ] **OEC-23.** Operational review cadence is named (weekly / monthly), or the absence is explicitly accepted.
- [ ] **OEC-24.** Log retention covers the longest expected investigation window.
- [ ] **OEC-25.** Incident-feedback mechanism is named (post-incident review template, action-item tracking).

## Cross-pillar boundary

- [ ] **OEC-26.** Findings clearly belonging to other pillars (Security, Reliability, Performance Efficiency, Cost, Sustainability) have been routed to the corresponding pillar skill rather than absorbed here.

## Final synthesis

- [ ] **OEC-27.** OE review block in `design.md` follows the template structure and lists every GAP with severity (HIGH / MEDIUM / LOW).
- [ ] **OEC-28.** Each HIGH gap is either resolved or has an explicit, time-bounded deferral rationale (e.g., "post-launch milestone, week 2").
- [ ] **OEC-29.** No HIGH gap remains for any contract whose status is being transitioned to `accepted` or `implemented`.

## Severity rollup for the review block

The review block summarises the checklist outcome as:

- **HIGH gaps**: count + list. These block transition.
- **MEDIUM gaps**: count + list. These should be addressed pre-launch.
- **LOW gaps**: count + list. These are noted for follow-up.
- **DEFER items**: count + summary. These are accepted ships-without-satisfying with documented rationale.

A review block with non-zero HIGH gaps and no explicit deferral for each is a failed OE review.
