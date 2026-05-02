# Performance Efficiency design questions

Loaded on demand by the `aws-waf-performance-efficiency-skill`. The questions the architect must answer for the Performance Efficiency pillar at design time. Each question has a documented intent so a missing or hand-waved answer can be flagged.

## How to use this file

For each question:

1. Apply it to the artefact (`design.md` and/or each `contracts/<slug>.md`).
2. Capture the answer — citation, rationale, or "no" — in the PE review block.
3. A missing answer is a finding, not a passing default. Record it as a gap with severity per the checklist.

The questions are grouped by sub-area. The order within a group is intentional: latency and throughput targets first (the contract with users), then compute, data, caching, and verification.

## Latency and throughput targets

- **Q-PE-1.** What is the named p50, p95, p99 latency budget per public-facing operation? Cite the source (SLO doc, requirements).
- **Q-PE-2.** What is the throughput floor (requests/second sustained, peak burst)?
- **Q-PE-3.** What is the latency budget per internal-only operation that participates in the public path?
- **Q-PE-4.** Are latency and throughput targets stated per-region, or globally? If per-region, name each.

## Compute selection

- **Q-PE-5.** For each compute component, what is the workload's traffic shape (steady, bursty, scheduled, batch, fan-out)?
- **Q-PE-6.** What runtime model was chosen (Lambda, ECS service, Fargate task, EC2 instance, Step Functions, Bedrock-managed) and why does the traffic shape justify it?
- **Q-PE-7.** What is the cold-start tolerance? If <100ms, what mitigations are named (provisioned concurrency, warm pool, always-on minimum)?
- **Q-PE-8.** What is the concurrency ceiling? Is it bounded by service quota, by IAM throttle, or by application config?
- **Q-PE-9.** Is the instance class / Lambda memory / Fargate task size justified by a benchmark or a published reference, or is it a guess?

## Data layer

- **Q-PE-10.** For each data store, what is the read-vs-write ratio?
- **Q-PE-11.** For each store, what indexes / partition keys / sort keys are designed for the dominant query pattern?
- **Q-PE-12.** Are there hot keys or hot partitions in the design? What mitigations apply?
- **Q-PE-13.** For relational stores, what is the connection-pool sizing and where is it pooled (RDS Proxy, application-tier)?

## Caching

- **Q-PE-14.** Where in the request path is caching applied (CloudFront edge, regional cache, ElastiCache, DAX, application-tier)?
- **Q-PE-15.** What is the cache key, the TTL, and the invalidation strategy?
- **Q-PE-16.** Are cache misses graceful (degraded-but-correct response) or fatal (5xx)?
- **Q-PE-17.** What is the cache-hit-rate target, and how is it measured?

## Network and data transfer

- **Q-PE-18.** Are large objects served through CloudFront with appropriate cache behaviours, or directly from S3?
- **Q-PE-19.** For cross-AZ or cross-region traffic, is the volume measured and bounded?
- **Q-PE-20.** Are payloads compressed at the edge (gzip, brotli) and at the application?

## Load testing and verification

- **Q-PE-21.** What is the load-test plan: target throughput, percentile thresholds, ramp profile, success criteria, environment?
- **Q-PE-22.** Will the load test exercise the dominant failure modes (downstream timeout, quota exceeded, cache miss storm)?
- **Q-PE-23.** What is the rollback signal if load-test results regress against a prior baseline?
- **Q-PE-24.** Is there a synthetic monitor that exercises the critical path in production at a documented cadence?

## What this section does NOT cover

- Runbooks, on-call rotation, dashboard URLs, deployment rollback — Operational Excellence pillar.
- Encryption-at-rest, IAM least-privilege, identity perimeter, secrets storage — Security pillar.
- Multi-AZ, multi-region failover, retry budgets, idempotency design — Reliability pillar.
- Pricing models, right-sizing for cost, untagged-resource detection, cost ceilings — Cost Optimization pillar.
- Region carbon footprint, fleet right-sizing for energy — Sustainability pillar.

If a finding falls into one of those, route it to the corresponding pillar skill rather than absorbing it here.
