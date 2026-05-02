# Performance Efficiency checklist

Loaded on demand by the `aws-waf-performance-efficiency-skill`. End-to-end checklist for the Performance Efficiency pillar at design time. Each item is satisfied with evidence, deferred with rationale, or flagged as a gap.

## How to use this checklist

For each item below:

1. Mark **PASS** with the evidence (file path + section, or citation).
2. Mark **DEFER** with a one-paragraph rationale (why this is OK to ship without satisfying).
3. Mark **GAP** when neither — the PE review block lists every GAP with severity.

The checklist is intentionally exhaustive at the cost of redundancy with `pe-design-questions.md` and `pe-antipatterns.md`. The questions are open-ended; the anti-patterns scan for known shapes; this checklist is the final pre-acceptance gate.

## Latency and throughput targets

- [ ] **PEC-1.** p50, p95, p99 latency budgets named per operation. Severity per `AP-PE-1`: HIGH gap for public-facing components; MEDIUM for internal.
- [ ] **PEC-2.** Each latency budget has a corresponding SLI: a metric query that measures it.
- [ ] **PEC-3.** Throughput floor named (sustained req/s and peak burst). Severity per `AP-PE-3`: HIGH on request path; MEDIUM for batch.
- [ ] **PEC-4.** Targets stated per-region or explicitly global with rationale.

## Compute selection

- [ ] **PEC-5.** Each compute component has a workload-shape rationale (steady / bursty / scheduled / batch / fan-out).
- [ ] **PEC-6.** Runtime choice (Lambda / ECS / Fargate / EC2 / Step Functions) tied to traffic shape, not team familiarity.
- [ ] **PEC-7.** Cold-start tolerance named; mitigations declared if budget is sub-100ms (per `AP-PE-6`).
- [ ] **PEC-8.** Concurrency ceiling bounded (service quota, IAM throttle, or application config).
- [ ] **PEC-9.** Instance class / Lambda memory / Fargate task size justified by benchmark or published reference.

## Data layer

- [ ] **PEC-10.** Read-vs-write ratio named per data store.
- [ ] **PEC-11.** Indexes / partition keys / sort keys aligned with dominant query pattern.
- [ ] **PEC-12.** Hot keys or hot partitions identified with mitigations.
- [ ] **PEC-13.** Connection-pool sizing named for relational stores (RDS Proxy or application-tier pool).

## Caching

- [ ] **PEC-14.** Cache layer placement decided per read-heavy path (or rationale why no cache is needed).
- [ ] **PEC-15.** Cache key, TTL, and invalidation strategy named.
- [ ] **PEC-16.** Cache-miss behaviour is graceful (fall-through to origin), not fatal.
- [ ] **PEC-17.** Cache-hit-rate target named with measurement approach.

## Network and data transfer

- [ ] **PEC-18.** Large-object delivery routed through CloudFront where applicable, or rationale documented.
- [ ] **PEC-19.** Cross-AZ or cross-region per-request traffic estimated and bounded.
- [ ] **PEC-20.** Payload compression enabled (gzip/brotli) at edge and at application.

## Load testing and verification

- [ ] **PEC-21.** Load-test plan named: target throughput, percentile thresholds, ramp profile, success criteria, environment.
- [ ] **PEC-22.** Load test exercises dominant failure modes (timeout, quota exceeded, cache miss storm).
- [ ] **PEC-23.** Baseline recorded for regression detection.
- [ ] **PEC-24.** Production synthetic monitor named with cadence.

## Cross-pillar boundary

- [ ] **PEC-25.** Findings clearly belonging to other pillars (Operational Excellence, Security, Reliability, Cost, Sustainability) have been routed to the corresponding pillar skill rather than absorbed here.

## Final synthesis

- [ ] **PEC-26.** PE review block in `design.md` follows the template structure and lists every GAP with severity (HIGH / MEDIUM / LOW).
- [ ] **PEC-27.** Each HIGH gap is either resolved or has an explicit, time-bounded deferral rationale.
- [ ] **PEC-28.** No HIGH gap remains for any contract whose status is being transitioned to `accepted` or `implemented`.

## Severity rollup for the review block

The review block summarises the checklist outcome as:

- **HIGH gaps**: count + list. These block transition.
- **MEDIUM gaps**: count + list. These should be addressed pre-launch.
- **LOW gaps**: count + list. These are noted for follow-up.
- **DEFER items**: count + summary. These are accepted ships-without-satisfying with documented rationale.

A review block with non-zero HIGH gaps and no explicit deferral for each is a failed PE review.
