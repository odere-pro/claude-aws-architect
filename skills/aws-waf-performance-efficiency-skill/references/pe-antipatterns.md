# Performance Efficiency anti-patterns

Loaded on demand by the `aws-waf-performance-efficiency-skill`. Catalogue of design-time anti-patterns the skill must surface, with severity guidance.

## How to use this file

For each anti-pattern, scan the artefact for the listed evidence pattern. If found, record a finding with:

- The anti-pattern's identifier (`AP-PE-N`).
- Severity (HIGH / MEDIUM / LOW per the per-pattern guidance).
- Concrete evidence: file path + section + the specific text that matched.

Severity guidance:

- **HIGH**: blocks acceptance; the contract or design cannot transition forward without addressing.
- **MEDIUM**: must be addressed or explicitly deferred with a rationale paragraph in the PE review block.
- **LOW**: noted in the review; does not block transition.

## Anti-pattern catalogue

### Latency and throughput targets

- **AP-PE-1 — Implicit latency target.** No named p50, p95, or p99 latency budget per public-facing operation. **Severity**: HIGH for public-facing components, MEDIUM for internal.
- **AP-PE-2 — Latency target without SLI.** Latency budget is named but no metric query measures it; the target cannot be evaluated. **Severity**: HIGH.
- **AP-PE-3 — Throughput floor undefined.** No named requests/second sustained or peak-burst figure. **Severity**: HIGH for any component on a request path; MEDIUM for batch.
- **AP-PE-4 — Targets copy-pasted from another feature.** Same latency/throughput as a sibling feature, different traffic profile, no rationale that the choice is still correct. **Severity**: LOW unless the traffic profile is dramatically different (then MEDIUM).

### Compute selection

- **AP-PE-5 — Compute justified only by team familiarity.** "We use ECS everywhere" is the sole rationale; no traffic-shape analysis. **Severity**: MEDIUM.
- **AP-PE-6 — Cold-start exposure on a low-latency path.** Lambda chosen for a sub-200ms-target API path with no provisioned concurrency, warm pool, or always-on minimum. **Severity**: HIGH.
- **AP-PE-7 — Unbounded concurrency.** No ceiling on Lambda concurrency, ECS desired-count maximum, or autoscaling target; runaway-cost and runaway-load risk both apply. **Severity**: HIGH.
- **AP-PE-8 — Memory or CPU sized by guess.** Lambda memory or Fargate CPU/memory chosen without benchmark or published reference; "we'll tune it later" is not a rationale. **Severity**: MEDIUM.
- **AP-PE-9 — Compute oversized for traffic shape.** EC2 fleet on a sporadic-request path that would fit Lambda or Fargate Spot; routes to Cost as well, but the PE concern is the over-provisioning hides the real performance ceiling. **Severity**: LOW (PE-side; Cost-side may rate higher).

### Data layer

- **AP-PE-10 — Index or partition-key design ignores dominant query.** DynamoDB partition key produces hot partitions for the common access pattern, or RDS table lacks the index for the dominant WHERE clause. **Severity**: HIGH.
- **AP-PE-11 — Hot key with no mitigation.** A known hot key (single-tenant identifier on a multi-tenant table, time-series with single-bucket writes) without sharding, write-through cache, or partition spreading. **Severity**: HIGH.
- **AP-PE-12 — Connection-pool sizing absent.** RDS or Aurora used without RDS Proxy and without an application-tier pool ceiling. **Severity**: MEDIUM.

### Caching

- **AP-PE-13 — Cache absent on hot read path.** A read-heavy path with no caching layer (CloudFront, ElastiCache, DAX, application-tier) and no rationale why the path is fast enough without one. **Severity**: MEDIUM (HIGH if the read-vs-write ratio is documented as >10:1 with no cache).
- **AP-PE-14 — Cache without invalidation strategy.** TTL is named but invalidation on write is not; stale reads after writes. **Severity**: MEDIUM.
- **AP-PE-15 — Cache miss is fatal.** Cache miss returns 5xx instead of falling through to the origin; cache becomes a SPOF for an availability-additive layer. **Severity**: HIGH.
- **AP-PE-16 — Cache key too coarse or too fine.** A single key used per tenant when per-resource caching is available, or per-request keys that never hit. **Severity**: LOW.

### Network and data transfer

- **AP-PE-17 — Large objects served directly from S3 to internet without CloudFront.** Latency tail and egress cost both impacted; mostly a Cost concern but PE bears the latency. **Severity**: LOW (PE-side).
- **AP-PE-18 — Cross-AZ or cross-region traffic unmeasured.** No estimate of the cross-AZ chatter for a per-request operation; latency tail unbounded. **Severity**: MEDIUM.
- **AP-PE-19 — No payload compression.** API responses or static assets served uncompressed; latency-on-the-wire higher than necessary. **Severity**: LOW.

### Load testing and verification

- **AP-PE-20 — No load-test plan.** Performance targets are named but no plan to verify them; targets are wishes. **Severity**: HIGH.
- **AP-PE-21 — Load test exercises happy path only.** Plan exists but does not exercise downstream timeout, quota exceeded, cache miss storm, or other failure modes. **Severity**: MEDIUM.
- **AP-PE-22 — No baseline to regress against.** Load test runs but no recorded baseline; cannot detect regression. **Severity**: MEDIUM.
- **AP-PE-23 — No production synthetic monitor.** Critical path verified in staging but never exercised post-deploy; first production traffic is the first production test. **Severity**: MEDIUM.

## What is NOT an anti-pattern (intentional design)

- "We chose Lambda with 256MB memory because the workload is sub-100ms steady-state and benchmarked at 80ms" — a documented, benchmark-backed choice. Not an anti-pattern.
- "Cache TTL is 5 minutes with no invalidation because the data is acceptably stale at that horizon" — a documented trade-off (latency vs freshness). Not an anti-pattern; the rationale is the load-bearing part.
- "We accept a 200ms p99 cold-start budget on the admin endpoint because the admin uses it 3x/day" — accepted-cost-per-business-frequency is a legitimate trade-off.
