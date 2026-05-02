# Pricing models

Loaded on demand by the `aws-waf-cost-optimization-skill` skill. Encodes the decision tree the agent uses to pick a pricing model and the workload-class eligibility table.

## Decision tree

The agent walks the tree in order; the first matching branch wins. Every choice is recorded in the contract's `cost:` block with the matched branch.

1. **Bursty, sub-second wake** → Lambda or Fargate, billed per invocation. No commitment, no idle waste, but per-invocation cost can dominate at very high request rates — the agent verifies the crossover against the `cost` MCP before locking the choice.
2. **Fault-tolerant, interruption-tolerable, ≤2-minute graceful drain** → Spot, with Spot-Fleet diversification across at least three instance types and two AZs. The contract declares the retry / checkpoint policy.
3. **Steady-state, ≥12-month commitment tolerable, instance family may change** → Compute Savings Plans. Most flexible: covers EC2, Fargate, and Lambda; flexes across family, region, OS, tenancy.
4. **Steady-state, instance family stable for 1–3 years** → Reserved Instances. Standard for max discount; Convertible for the right to change family/OS later. Convertible discount is smaller but the option value is real for new workloads.
5. **Default / not yet predictable** → On-Demand, with an explicit "revisit at <date>; owner: <name>" item written into `tasks.md`. On-Demand is the right answer when usage is genuinely unknown — it is not the right answer indefinitely.

## Workload-class eligibility

The table is the source of truth for what workloads can take which pricing model. Spot-ineligibility is encoded here so the agent never proposes Spot for a class that cannot tolerate it.

| Workload class                                     | Lambda/Fargate    | Spot               | Savings Plan / RI | On-Demand |
| -------------------------------------------------- | ----------------- | ------------------ | ----------------- | --------- |
| Stateless web tier, autoscaled                     | Yes               | Yes (mixed fleet)  | Yes               | Yes       |
| Stateful database (RDS/Aurora/DynamoDB)            | No                | No                 | RI for RDS only   | Yes       |
| Real-time (sub-second p99) user-facing service     | Yes               | No                 | Yes               | Yes       |
| Batch ETL with checkpointing                       | Fargate-spot OK   | Yes                | Optional          | Yes       |
| ML training (interruption-tolerable, checkpointed) | No                | Yes                | Optional          | Yes       |
| ML inference (latency-sensitive)                   | Yes (provisioned) | No                 | Yes               | Yes       |
| GPU/CUDA workload                                  | Limited           | Sometimes (verify) | Yes (Convertible) | Yes       |
| Long-running stateful workers (Kafka, Redis)       | No                | No                 | Yes               | Yes       |
| Build/CI runners                                   | Yes               | Yes                | Optional          | Yes       |
| Dev/test environments (off-hours-stoppable)        | Yes               | Yes                | No (waste)        | Yes       |

Workload classes not in the table fall through to "verify with the user before committing"; do not extrapolate.

## Commitment-term decisions

When the agent chooses Savings Plans or RIs, the term and coverage decisions are explicit:

- **Term**: 1 year is the default. 3 years gives a higher discount but the customer is locked in; only choose 3 years when the workload is provably stable.
- **Coverage target**: aim for 60–80% of the steady-state run-rate covered by commitments, leaving 20–40% on-demand for elasticity. 100% coverage is rarely correct because it removes the buffer that absorbs traffic shocks without paying interruption costs.
- **Payment option**: All-Upfront > Partial-Upfront > No-Upfront for discount magnitude; the customer's cash-flow constraint is the deciding input. The contract records the chosen payment option and the rationale.

## Anti-patterns

The agent rewrites the contract when any of these appears:

- "On-demand for now, we'll switch later" — without a date and an owner this is the cost-creep antipattern. Write the follow-up into `tasks.md` or pick a commitment.
- "Spot for everything to save money" — Spot interruption is real and most workload classes do not tolerate it. The eligibility table is the gate.
- "100% RI coverage" — leaves no headroom; traffic spikes pay on-demand at full rate.
- "Convertible RIs are always safer than Standard" — Convertible has a smaller discount; the option value must be worth the lost discount, which depends on the workload's stability profile.
- "Savings Plan first, then RI on top" — they compose, but the agent must declare the layering explicitly so the procurement team can act on it.
