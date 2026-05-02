# Reliability checklist

Loaded on demand by the `aws-waf-reliability-skill`. End-to-end checklist for the Reliability pillar at design time. Each item is satisfied with evidence, deferred with rationale, or flagged as a gap.

## How to use this checklist

For each item below:

1. Mark **PASS** with the evidence (file path + section, or citation).
2. Mark **DEFER** with a one-paragraph rationale (why this is OK to ship without satisfying).
3. Mark **GAP** when neither — the Reliability review block lists every GAP with severity.

The checklist is intentionally exhaustive at the cost of redundancy with `rel-design-questions.md` and `rel-antipatterns.md`. The questions are open-ended; the anti-patterns scan for known shapes; this checklist is the final pre-acceptance gate.

## Recovery objectives and DR strategy

- [ ] **RELC-1.** Every critical-path component has RTO named with units and a documented source (business stakeholder, SLA, regulation).
- [ ] **RELC-2.** Every critical-path component has RPO named with units and a documented source.
- [ ] **RELC-3.** A DR strategy is named (backup-restore / pilot light / warm standby / multi-site active-active) and is consistent with the RTO/RPO numbers.
- [ ] **RELC-4.** The DR strategy has a named validation mechanism — restore test, failover drill, or chaos experiment — with cadence and owner.
- [ ] **RELC-5.** Replication mechanism and lag assumption are named for every replicated stateful component.

## Availability posture

- [ ] **RELC-6.** Every stateful component names AZ posture (single-AZ with rationale, multi-AZ active-passive, multi-AZ active-active).
- [ ] **RELC-7.** Every compute component names AZ distribution; non-balanced distributions carry a rationale.
- [ ] **RELC-8.** Multi-region designs name the routing mechanism and the consistency model.
- [ ] **RELC-9.** Per-component SLAs are cited for every managed service in the design.
- [ ] **RELC-10.** Composed feature-level availability is derived from the topology (serial vs parallel) and recorded.

## Runtime resilience

- [ ] **RELC-11.** Every cross-service call has an explicit timeout value.
- [ ] **RELC-12.** Every cross-service call has a bounded retry policy with exponential backoff and jitter.
- [ ] **RELC-13.** Every retried write has a named idempotency strategy (token, conditional write, dedupe).
- [ ] **RELC-14.** Circuit breakers or bulkheads are used where a downstream has a documented partial-failure mode; threshold and recovery condition are named.
- [ ] **RELC-15.** Throttling and graceful-degradation behaviour at quota or capacity limits is documented per call site.

## Capacity and quotas

- [ ] **RELC-16.** Relevant Service Quotas are named for every AWS service used at scale, with a headroom assumption.
- [ ] **RELC-17.** Auto-scaling policies have an upper bound; the bound is justified against downstream capacity and cost.
- [ ] **RELC-18.** Cold-start or warm-up profile is documented for serverless and just-in-time-provisioned components on latency-sensitive paths.

## Health, detection, recovery

- [ ] **RELC-19.** Health checks distinguish shallow versus deep where the dependency topology requires it.
- [ ] **RELC-20.** Failure-detection latency is named and the validation mechanism (synthetic probe, real-traffic alarm) is documented.
- [ ] **RELC-21.** Recovery automation is named for every top failure mode; manual-only recovery on a tight RTO is flagged.

## Dependency and failure-mode analysis

- [ ] **RELC-22.** Dependency map present: upstream and downstream dependencies itemised with criticality labels (critical / degraded / optional).
- [ ] **RELC-23.** FMA present: top 3–7 failure modes with detection, blast radius, mitigation, and recovery owner.
- [ ] **RELC-24.** Accepted failure modes carry a named approver, rationale, and re-evaluation conditions.

## Cross-pillar boundary

- [ ] **RELC-25.** Findings clearly belonging to other pillars (Operational Excellence, Security, Performance Efficiency, Cost, Sustainability) have been routed to the corresponding pillar skill rather than absorbed here.

## Final synthesis

- [ ] **RELC-26.** Reliability review block in `design.md` follows the template structure and lists every GAP with severity (HIGH / MEDIUM / LOW).
- [ ] **RELC-27.** Each HIGH gap is either resolved or has an explicit, time-bounded deferral rationale (e.g., "post-launch milestone, week 2").
- [ ] **RELC-28.** No HIGH gap remains for any contract whose status is being transitioned to `accepted` or `implemented`.

## Severity rollup for the review block

The review block summarises the checklist outcome as:

- **HIGH gaps**: count + list. These block transition.
- **MEDIUM gaps**: count + list. These should be addressed pre-launch.
- **LOW gaps**: count + list. These are noted for follow-up.
- **DEFER items**: count + summary. These are accepted ships-without-satisfying with documented rationale.

A review block with non-zero HIGH gaps and no explicit deferral for each is a failed Reliability review.
