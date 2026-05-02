# Reliability anti-patterns

Loaded on demand by the `aws-waf-reliability-skill`. Catalogue of design-time anti-patterns the skill must surface, with severity guidance.

## How to use this file

For each anti-pattern, scan the artefact for the listed evidence pattern. If found, record a finding with:

- The anti-pattern's identifier (`AP-REL-N`).
- Severity (HIGH / MEDIUM / LOW per the per-pattern guidance).
- Concrete evidence: file path + section + the specific text that matched.

Severity guidance:

- **HIGH**: blocks acceptance; the contract or design cannot transition forward without addressing.
- **MEDIUM**: must be addressed or explicitly deferred with a rationale paragraph in the Reliability review block.
- **LOW**: noted in the review; does not block transition.

## Anti-pattern catalogue

### Recovery objectives and DR strategy

- **AP-REL-1 — RTO/RPO undefined or "TBD".** A critical-path component without RTO and RPO named with units. **Severity**: HIGH.
- **AP-REL-2 — DR strategy inconsistent with RTO/RPO.** Backup-restore named with a 5-minute RTO; warm standby promised with no replicated state. The strategy must be achievable with the chosen mechanisms. **Severity**: HIGH.
- **AP-REL-3 — DR plan never validated.** Strategy declared but no restore test, failover drill, or chaos experiment is named. **Severity**: MEDIUM.
- **AP-REL-4 — Replication lag assumption absent.** Asynchronous replication is used but the lag bound is not stated; an RPO claim cannot be verified. **Severity**: MEDIUM.

### Availability posture

- **AP-REL-5 — Single-AZ stateful component without rationale.** Production database, queue, or cache pinned to one AZ with no documented trade-off. **Severity**: HIGH.
- **AP-REL-6 — Multi-AZ claimed but not configured.** Component documented as Multi-AZ but the IaC or design omits the Multi-AZ flag, replicated subnet group, or cross-AZ replica. **Severity**: HIGH.
- **AP-REL-7 — Compute pinned to one AZ.** Auto-Scaling group, ECS service, or EKS node group with a single subnet. **Severity**: HIGH unless explicitly justified (e.g. AZ-affinity for low-latency state).
- **AP-REL-8 — Multi-region claim without consistency model.** Multi-region active-active or active-passive declared with no statement of the consistency model (eventual / strong / read-your-writes). **Severity**: MEDIUM.
- **AP-REL-9 — Availability budget not composed.** Per-component SLAs are cited but the composed feature-level availability is not derived from the topology. **Severity**: MEDIUM.

### Runtime resilience

- **AP-REL-10 — Naked timeout.** Cross-service call with no explicit timeout, or the timeout is "default" without naming a value. **Severity**: HIGH.
- **AP-REL-11 — Unbounded retries.** Retry policy with no maximum attempts, or with a backoff that does not cap. **Severity**: HIGH.
- **AP-REL-12 — Retry without jitter.** Retry policy with exponential backoff but no jitter; multiple callers retry in lock-step under a downstream outage. **Severity**: MEDIUM.
- **AP-REL-13 — Non-idempotent retried write.** A retried call mutates state without an idempotency token, conditional write, or consumer-side dedupe. **Severity**: HIGH.
- **AP-REL-14 — No circuit breaker on flaky downstream.** A downstream with a documented partial-failure mode is called without a circuit breaker, isolating no failure domain. **Severity**: MEDIUM.
- **AP-REL-15 — Hidden throttling behaviour.** At quota or capacity limit the design has no documented graceful-degradation strategy; the caller sees raw 5xx or silent stall. **Severity**: MEDIUM.

### Capacity and quotas

- **AP-REL-16 — Quota assumption absent.** Service is used at scale (Lambda concurrency, DynamoDB throughput, API Gateway rate, RDS connections) but the relevant Service Quota and headroom assumption are not named. **Severity**: HIGH.
- **AP-REL-17 — Auto-scaling without upper bound.** Scaling policy with no maximum capacity; runaway demand can collapse downstream services or blow the cost ceiling. **Severity**: MEDIUM.
- **AP-REL-18 — Cold-start ignored on latency-sensitive path.** Lambda or Fargate on a synchronous user-facing path with no provisioned concurrency, warm pool, or pre-warming, and no documented cold-start budget. **Severity**: MEDIUM.

### Health, detection, recovery

- **AP-REL-19 — Shallow-only health check on transitive dependency.** Component depends on a downstream but its health check only verifies its own process; downstream outage produces a healthy-but-broken state. **Severity**: MEDIUM.
- **AP-REL-20 — Failure-detection latency unspecified.** Time from fault to alarm is unstated; recovery automation cannot be reasoned about. **Severity**: MEDIUM.
- **AP-REL-21 — Recovery automation absent for top failure modes.** FMA names a top failure mode but recovery is "page on-call" with no automated mitigation, and the RTO is too tight for human-only response. **Severity**: HIGH.

### Dependency and failure-mode analysis

- **AP-REL-22 — Dependency map absent.** No itemised list of upstream and downstream dependencies; blast radius cannot be reasoned about. **Severity**: HIGH.
- **AP-REL-23 — FMA absent.** Reliability review block has no failure-mode analysis. **Severity**: HIGH.
- **AP-REL-24 — Failure modes listed without mitigations.** Failure modes are itemised but several have empty or hand-waved mitigations. **Severity**: HIGH.
- **AP-REL-25 — Accepted failure mode without sign-off.** A failure mode is documented as "accepted" but no named approver or rationale is recorded. **Severity**: HIGH.

## What is NOT an anti-pattern (intentional design)

- "Single-AZ ephemeral build cache, AZ-failure tolerated by rebuild" — a single-AZ component with a documented rationale and an RTO that admits a rebuild is legitimate. Not an anti-pattern.
- "No retry on a synchronous user-facing call where retry would extend perceived latency past the SLO" — a deliberate no-retry policy with the latency rationale recorded is legitimate. Not an anti-pattern; the FMA should still cover the failure path.
- "Backup-restore DR with a 4-hour RTO for a non-revenue internal tool" — a low DR posture matching a low RTO with explicit business sign-off is legitimate. Not an anti-pattern.
