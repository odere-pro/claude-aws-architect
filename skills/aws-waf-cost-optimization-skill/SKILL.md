---
name: aws-waf-cost-optimization-skill
description: |
  **WORKFLOW SKILL** — Apply the AWS Well-Architected Cost Optimization
  pillar: pricing-model selection (on-demand / reserved / savings plans /
  spot), right-sizing, idle-resource detection, storage tiering, data-egress
  minimization, and tag-based cost allocation with budget alarms.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent makes a decision that has a recurring AWS bill attached: instance family choice, storage class, scaling policy, region pairing, networking topology, or commitment-based pricing. Cost is a first-class design pillar, not a post-hoc audit.

Trigger conditions:

- The orchestrator's solution-architect specialist is producing `design.md` and must record explicit cost trade-offs alongside the other pillars.
- A component contract under `.claude/specs/<feature>/contracts/<name>.md` declares a long-running resource (anything not strictly request-driven) — the contract must record the chosen pricing model and the rationale.
- The user requests a cost estimate, a Reserved-Instance / Savings-Plans review, or a "lower the bill" pass on an existing design.
- The implementation specialist is selecting between equivalent AWS services (e.g. SQS vs Kinesis, RDS vs Aurora, ALB vs NLB) and the cost differential is material.
- The discovery specialist is enumerating non-functional requirements and a cost ceiling, budget threshold, or unit-economics target is in scope.
- The sustainability skill is recommending Graviton or scale-to-zero — verify the cost outcome is consistent with the user's commitment posture before agreeing.

Do not apply this skill to pricing decisions for non-AWS services, to one-shot operational expenses (e.g. a `kms encrypt` call inside a Lambda — covered by the per-invocation budget), or to per-request micro-optimisations that the workload's traffic pattern does not justify.

## Procedure

1. **Get authoritative pricing.** Issue a `cost` MCP call (the `aws-pricing` server) for every priced resource. Cite the result via the `aws-spec-grounding` skill's `<server>:<short-key>` format. Stale or pretrained pricing is forbidden — pricing changes quarterly and inference is a costly source of error.
2. **Pick the pricing model.** Consult `references/pricing-models.md`. Default decision tree:
   - **Steady-state, ≥12-month commitment tolerable** → Compute Savings Plans (most flexible across instance family, region, OS). Record the commitment term and coverage target in the contract.
   - **Steady-state, instance family stable for 1–3 years** → Reserved Instances (Standard for max discount, Convertible for flexibility).
   - **Fault-tolerant, interruption-tolerable** → Spot, with Spot-Fleet diversification and a documented retry policy.
   - **Bursty, sub-second wake** → Lambda or Fargate (per-invocation pricing).
   - **Default / not yet predictable** → On-Demand, with an explicit "revisit at <date> when usage data exists" item in tasks.
3. **Right-size before committing.** Use Compute Optimizer recommendations (via the `cw` MCP) on existing workloads, or measured peak from load tests on new ones. The contract records the actual percentile used (e.g. "p99 over 14 days") and the chosen instance size. Coordinate with the sustainability skill — Graviton + right-sizing is the same lever for both pillars.
4. **Tier storage by access pattern.** S3 lifecycle: Standard → Standard-IA after 30d → Glacier Instant Retrieval after 90d → Glacier Deep Archive after 180d, unless retrieval-time SLOs forbid. EBS gp3 over gp2 (separate IOPS/throughput billing eliminates over-provisioning waste). Apply CloudWatch Logs retention; never leave the default of "never expire". Each lifecycle policy is recorded in the contract's `cost:` block.
5. **Cap data-egress costs.** Data leaving an AWS region or AWS as a whole is the largest hidden line item in many bills. Use VPC endpoints (Gateway endpoints for S3/DynamoDB are free; Interface endpoints have an hourly charge that almost always pays for itself versus NAT-Gateway egress). Co-locate data and compute in the same AZ where the workload's availability profile permits. Cache at the edge (CloudFront) instead of repeatedly serving from origin. Each cross-region or internet-egress data path is enumerated in the `cost:` block with an estimated monthly volume.
6. **Tag for allocation.** Every component contract declares tags: `Project`, `Environment`, `Owner`, `CostCenter`, plus any workload-specific tag the customer's tagging policy demands. Cost allocation tags must be enabled at the account / Organizations level — note this in the design summary if not already configured.
7. **Set budget alarms.** Each design declares at least one AWS Budgets alarm threshold (typically 80% of the projected monthly run-rate as the warning, 100% as the action threshold). The action is documented (notify owner; do not auto-shut-down without an explicit user opt-in).
8. **Record cost projection in the contract.** The `cost:` block emits: chosen pricing model, monthly run-rate range (rough order of magnitude is acceptable when pricing API is degraded — use the `cost-rom-only` marker), commitment term and coverage if applicable, cost-allocation tags, and any deviation from the default decision tree with rationale. The orchestrator's merge step aggregates these into a system-level projection in the design summary.

## Gotchas

- **Do not equate "on-demand" with "default; we'll fix it later."** On-demand is the right answer when usage is genuinely unpredictable; otherwise the design owes a Savings Plan / RI commitment review with a date and an owner. "On-demand for now" without a follow-up commitment is how bills creep.
- **Do not propose Spot for stateful or latency-sensitive workloads.** Spot interruption notices are 2 minutes; a database, a long-running ML training run with checkpointing, or a real-time service does not tolerate that. The `references/pricing-models.md` table lists workload classes by Spot eligibility.
- **Do not estimate costs without the `cost` MCP.** Pretrained AWS pricing is months out of date in the best case; in the worst case the price has changed, the SKU has been replaced, or a Savings Plan structure has been renamed. Every cost figure in a design must trace to a `cost` MCP citation.
- **Do not confuse Savings Plans and Reserved Instances.** Savings Plans give a usage-amount commitment that flexes across instance family and region; RIs reserve specific capacity. Mixing the language confuses the user and the procurement team.
- **Do not silently drop the cost section on degraded MCP.** Emit `cost-rom-only` and a factor-of-two range; do not omit the block. A missing cost block reads as "we ignored cost" to a reviewer.
- **Do not auto-suggest aggressive lifecycle transitions for cold data.** Glacier tiers carry minimum-storage-duration charges (30/90/180 days) and per-retrieval costs. Optimising for low monthly storage cost can make the next regulatory retrieval expensive. The `references/storage-tiers.md` reference encodes the trade-offs.
- **Do not propose data-egress reductions that change semantics.** Disabling cross-region replication reduces egress, but it also degrades the DR posture. Each egress reduction must declare which non-functional requirement it preserves and which it weakens, if any.
- **Do not over-tag.** Tags have per-resource budgets; the customer's tagging policy is the authority. Adding three new tags "for cost reporting" without checking the policy creates audit failures.
- **Do not promise "savings" without a reference baseline.** "This will save 30%" is meaningless without a baseline (current cost, on-demand-equivalent cost, or an explicit competing design). The contract names the baseline or the savings figure is dropped.

## Boundaries

- This skill MUST NOT make pricing-model commitments without an explicit user decision. Recommendations go in the contract; the procurement action goes to the user.
- This skill MUST NOT auto-shut-down resources to "save money". Idle handling is documented in the contract; execution is a separate, human-confirmed step.
- This skill MUST NOT report a cost figure as authoritative without a `<server>:<short-key>` citation produced by `aws-spec-grounding` from a `cost` MCP call.
- This skill MUST NOT override the security pillar where they conflict — the merge contract's priority order applies (security > facts > cost > convergence > recency).
- This skill MUST NOT delete user data, snapshots, or backups to reduce storage cost. Retention policy is a business decision; cost optimisation operates within it, never overrides it.
- This skill MUST NOT propose Spot for any workload class flagged Spot-ineligible in `references/pricing-models.md`.
- This skill MUST NOT couple to the sustainability pillar by force; coordinate where they agree (Graviton, scale-to-zero, lifecycle), surface the conflict where they disagree (e.g. cheap region with high carbon intensity).

## Quality Checks

Before returning the cost block, confirm:

- Every priced resource has a `<server>:<short-key>` citation traceable to a `cost` MCP call (or the `cost-rom-only` marker is present with an explicit rationale and a factor-of-two range).
- Every long-running resource declares an explicit pricing model (`on-demand` / `reserved-instance` / `savings-plan` / `spot` / `lambda-per-invocation` / `fargate-per-invocation`); a missing declaration is a contract-validation failure.
- Every non-`on-demand` choice records the commitment term and the coverage target.
- Every `on-demand` choice records the date and owner of the future commitment review.
- Every storage resource declares a lifecycle policy or an explicit single-tier choice with retention.
- Every cross-AZ or cross-region data path is enumerated with an estimated monthly volume; the egress line item is not "TBD".
- The contract carries the four mandatory cost-allocation tags (`Project`, `Environment`, `Owner`, `CostCenter`) plus any customer-specific tags from the tagging policy.
- At least one AWS Budgets alarm threshold is declared with a documented action.
- The design summary aggregates per-component cost into a monthly run-rate range (point + factor-of-two band) plus a commitment-coverage percentage when applicable.
