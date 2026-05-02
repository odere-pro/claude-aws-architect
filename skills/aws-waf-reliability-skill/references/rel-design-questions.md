# Reliability design questions

Loaded on demand by the `aws-waf-reliability-skill`. The questions the architect must answer for the Reliability pillar at design time. Each question has a documented intent so a missing or hand-waved answer can be flagged.

## How to use this file

For each question:

1. Apply it to the artefact (`design.md` and/or each `contracts/<slug>.md`).
2. Capture the answer — citation, rationale, or "no" — in the Reliability review block.
3. A missing answer is a finding, not a passing default. Record it as a gap with severity per the checklist.

The questions are grouped by sub-area. The order within a group is intentional: recovery objectives first (the contract with the business), then availability posture, then runtime resilience, then dependency and failure-mode analysis.

## Recovery objectives and DR strategy

- **Q-REL-1.** What is the RTO (recovery time objective) for this feature? Cite the value with units (minutes/hours) and the source — business stakeholder, SLA contract, or regulatory constraint.
- **Q-REL-2.** What is the RPO (recovery point objective) for this feature? Cite the value with units (transactions, seconds, minutes) and the source.
- **Q-REL-3.** Which DR strategy is chosen — backup-restore, pilot light, warm standby, or multi-site active-active? Justify the choice against the RTO and RPO.
- **Q-REL-4.** How is the DR strategy validated? Named restore tests, named failover drills, or a documented chaos experiment.
- **Q-REL-5.** What is the data-replication mechanism for stateful components (synchronous Multi-AZ, asynchronous cross-region replication, snapshot ship-and-restore)? What is the replication lag assumption?

## Availability posture

- **Q-REL-6.** For each stateful component, what is the AZ posture — single-AZ, multi-AZ active-passive, multi-AZ active-active? If single-AZ, what is the rationale (non-production, cost-bounded, ephemeral)?
- **Q-REL-7.** For each compute component, what is the AZ distribution — pinned to one AZ, balanced across AZs, or AZ-affinity for state locality? Justify any non-balanced choice.
- **Q-REL-8.** Is the feature multi-region? If yes, what is the routing mechanism (Route 53 health-check failover, Global Accelerator, application-layer routing) and what is the consistency model across regions?
- **Q-REL-9.** What is the AWS service SLA for each managed service in the design (e.g. RDS Multi-AZ 99.95%, S3 99.99%)? Cite each SLA used in the availability budget calculation.
- **Q-REL-10.** What is the composed availability target for the feature, derived from the per-component SLAs and the topology (serial vs parallel dependencies)?

## Runtime resilience

- **Q-REL-11.** For every cross-service call, what is the timeout? Naked timeouts (default-of-default) are not a value.
- **Q-REL-12.** For every cross-service call, what is the retry policy — bounded attempts, exponential backoff, jitter? Unbounded retries are a HIGH anti-pattern.
- **Q-REL-13.** For every retried write, what is the idempotency strategy — idempotency token, conditional write, dedupe at consumer? Non-idempotent retried writes are a HIGH anti-pattern.
- **Q-REL-14.** Are circuit breakers or bulkheads used to isolate failure domains? Name the threshold and the recovery condition.
- **Q-REL-15.** What is the throttling and graceful-degradation behaviour at quota or capacity limits — shed load, queue, return cached, return error? What is communicated to the caller?

## Capacity and quotas

- **Q-REL-16.** For each AWS service used, what are the relevant Service Quotas (Lambda concurrency, DynamoDB partition throughput, RDS connections, API Gateway rate)? What is the headroom assumption (e.g. peak demand at 60% of quota)?
- **Q-REL-17.** Is auto-scaling configured? Name the scaling metric, the cooldown, and the upper bound. An unbounded scaling policy is itself a reliability risk (cost runaway, downstream collapse).
- **Q-REL-18.** What is the cold-start or warm-up profile for serverless and just-in-time-provisioned components? Is provisioned concurrency, warm pools, or pre-warming used?

## Health, detection, recovery

- **Q-REL-19.** What are the health-check definitions — shallow (process up) versus deep (transitive dependency check)? Where is each used (ELB, Route 53, ECS, Auto Scaling)?
- **Q-REL-20.** What is the failure-detection latency — time from fault to alarm — and how is it validated (synthetic probe, real-traffic alarm, dashboard heartbeat)?
- **Q-REL-21.** What is the recovery automation — manual operator action, automated failover, self-healing scale-up — for each top failure mode?

## Dependency and failure-mode analysis

- **Q-REL-22.** What are the upstream and downstream dependencies of this feature? Itemise them and label each as critical / degraded-operation / optional.
- **Q-REL-23.** What is the failure-mode analysis (FMA) for this feature? Itemise the top 3–7 failure modes with detection, blast radius, mitigation, and recovery owner.
- **Q-REL-24.** Are any failure modes explicitly accepted (no mitigation)? If yes, document the acceptance with sign-off and the conditions under which it would be re-evaluated.

## What this section does NOT cover

- Runbooks, on-call rotation, dashboard URLs, deployment rollback — Operational Excellence pillar.
- Least-privilege IAM, encryption decisions, threat model — Security pillar.
- Compute selection, caching strategy, load-test plan — Performance Efficiency pillar.
- Cost ceilings, right-sizing, untagged-resource detection — Cost Optimization pillar.
- Region carbon footprint, fleet right-sizing for energy — Sustainability pillar.

If a finding falls into one of those, route it to the corresponding pillar skill rather than absorbing it here.
