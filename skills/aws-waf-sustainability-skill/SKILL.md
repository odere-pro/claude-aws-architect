---
name: aws-waf-sustainability-skill
description: |
  **WORKFLOW SKILL** — Apply the AWS Well-Architected Sustainability pillar:
  low-carbon region selection, Graviton right-sizing, managed/serverless
  over self-hosted, storage lifecycle tiering, idle-resource shutdown, and
  data-transfer minimization.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent designs, reviews, or right-sizes AWS resources where energy, carbon impact, or wasted capacity is a stake. In practice that is essentially every solution-architect or implementation pass that touches compute, storage, or data movement.

Trigger conditions:

- The orchestrator's solution-architect specialist is producing `design.md` and must honor the Well-Architected Sustainability pillar alongside the other pillars.
- A component contract under `.claude/specs/<feature>/contracts/<name>.md` is being authored or revised; the pillar must inform the choice of compute family, storage tier, and region.
- A cost-pillar review is concluding; sustainability concerns frequently overlap (right-sizing, scale-to-zero, Graviton) and must be reconciled, not duplicated.
- The user explicitly asks for a "green" architecture, a carbon report, or low-environmental-impact options.
- A region-selection decision is on the table — sustainability is one of three inputs (with cost and latency).

Do not apply this skill to non-AWS workloads, to cost-only optimisations that have no compute or storage impact (e.g. a Reserved-Instance commitment review), or to retrospective carbon-footprint reporting (that is a separate quarterly workflow, not a design-time skill).

## Procedure

1. **Pick the lowest-carbon viable region.** Consult `references/region-carbon-tiers.md`. Tier-1 regions (≥95% renewable energy per AWS-published figures) are eligible by default. If data-residency or latency constraints exclude tier-1, pick the lowest-carbon region in the eligible set and label the deviation in the contract's `sustainability:` block with the specific constraint that drove the choice.
2. **Default to Graviton.** Choose `arm64` instance families (`t4g`, `m7g`, `c7g`, `r7g`, `m8g`, `c8g`) unless the workload provably requires `x86_64`. Every non-Graviton choice must carry a `requires-x86: <reason>` rationale in the contract — common legitimate reasons are documented in `references/graviton-eligibility.md`.
3. **Right-size before scaling.** Issue a `cw` MCP query for Compute Optimizer recommendations on existing workloads, or use the workload's measured peak from load tests. Avoid the "round up to be safe" antipattern; the contract must record the actual measured peak and the percentile chosen (e.g. "p99.9 over 14 days").
4. **Default to managed/serverless.** Lambda, Fargate, App Runner, EventBridge, SQS, SNS, DynamoDB on-demand — these scale to zero and amortize cooling/idle across thousands of customers. A self-hosted EC2 / ECS-on-EC2 / RDS choice must justify in the contract why a managed equivalent does not fit (latency floor, license model, library constraint).
5. **Tier storage by access pattern.** Default S3 lifecycle: Standard → Standard-IA after 30 days → Glacier Instant Retrieval after 90 → Glacier Deep Archive after 180, unless retrieval-time SLOs forbid. Prefer EBS gp3 over gp2 (gp3 charges separately for IOPS and throughput, eliminating idle waste). Apply CloudWatch Logs retention; never leave the default of "never expire".
6. **Cap data transfer.** Co-locate compute and data in the same AZ where the workload's availability profile permits; use VPC endpoints for AWS-API traffic; avoid cross-region replication unless DR or compliance demands it. Cache at the edge (CloudFront) instead of repeatedly serving from origin. Each cross-AZ or cross-region data path must be enumerated in the `sustainability:` block.
7. **Schedule for idle.** Non-prod EC2 / RDS / Redshift on a stop-overnight or stop-on-weekend schedule via EventBridge + Lambda. Spot for fault-tolerant batch. Auto-Scaling group with `min=0` for development environments. The contract enumerates expected duty cycle for every long-running resource.
8. **Record carbon impact in the contract.** Each component contract emits a `sustainability:` block: chosen region tier, instance arch, storage tier, idle handling, and any deviations with rationale. The orchestrator's merge step aggregates these into the design summary so the user sees system-level sustainability posture.

## Gotchas

- **Do not equate cost with carbon.** They correlate but are not identical. A Spot instance may be cheaper without being lower-carbon if the underlying region runs predominantly on coal. Always check region carbon tier independently of price.
- **Do not assume Graviton is a drop-in.** Some libraries (CUDA workloads, certain proprietary binaries, x86-only Java agents, x86-only Python wheels for niche scientific packages) do not yet support `arm64`. The contract must record verified support, not assumed support.
- **Do not over-tier storage.** Lifecycle transitions cost money and compute, and Glacier tiers carry minimum-storage-duration charges (30/90/180 days). For data accessed weekly, Standard-IA after 30 days is correct; aggressive 7-day transitions thrash the lifecycle engine without saving meaningful energy.
- **Do not treat the AWS Customer Carbon Footprint Tool as real-time.** It is a quarterly retrospective report with ≥3 months lag. Use it for trend analysis and reporting, not for design-time decisions — those use the per-region carbon-intensity tier table.
- **Do not silently drop the sustainability section.** When the pillar is degraded (Compute Optimizer signal missing, region carbon tier not yet published for a new region), label `sustainability-advisory` per the `aws-mcp-routing` degraded-mode rules; do not omit the block.
- **Do not propose unverified renewable-energy claims.** AWS's published per-region carbon-intensity figures are the authoritative source; agents must not infer "this region is 100% renewable" from marketing copy.
- **Do not conflate sustainability with shutdown alone.** A resource that runs at 5% utilisation 24/7 is worse than the same resource running at 60% utilisation eight hours a day. Right-sizing is the first lever; idle scheduling is the second.

## Boundaries

- This skill MUST NOT make region-selection decisions in isolation. Latency, data-residency, and cost are weighed together; sustainability is one input, not the sole criterion.
- This skill MUST NOT mandate Graviton when the workload's runtime stack does not support `arm64`; record the constraint in the contract and move on without further objection.
- This skill MUST NOT instruct the agent to remove existing provisioned capacity unless the contract has measured idle headroom from the `cw` MCP server; phantom headroom can break SLOs.
- This skill MUST NOT report a carbon figure as authoritative without a citation to the AWS Customer Carbon Footprint Tool or the published per-region carbon-intensity table — use the `<server>:<short-key>` format defined by `aws-spec-grounding`.
- This skill MUST NOT delete user data to "save storage". Retention policy is a business decision; sustainability optimises within the policy, never overrides it.
- This skill MUST NOT override the cost pillar where they conflict; the merge contract's priority order applies (security > facts > cost > convergence > recency), and sustainability is an input to "facts" via the carbon-tier table.

## Quality Checks

Before returning the sustainability block, confirm:

- The chosen region appears in the carbon-tier table with a tier label, OR the deviation is explicitly justified with the constraint that drove the choice.
- Every compute resource declares its instance architecture (`arm64` or `x86_64`); non-Graviton choices carry a `requires-x86: <reason>` rationale.
- Every storage resource declares its lifecycle policy, OR the contract states "single-tier with N-day retention" as the explicit choice.
- Every component contract contains a `sustainability:` block — no missing blocks, no empty blocks.
- Idle handling is declared: dev/non-prod resources have a shutdown schedule; prod resources declare expected duty cycle as a percentage.
- The aggregate cross-component summary (region mix, dominant arch, storage-tier distribution, total cross-region data paths) is included in the design summary.
- Every cited carbon figure carries a `<server>:<short-key>` reference traceable in the grounding ledger; uncited figures are forbidden.
