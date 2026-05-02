# `claude-aws-architect-cost` — playbook

Cost-only review power. Bundles `cost`, `kb` MCP servers, the `aws-waf-cost-optimization-skill`, the routing / grounding / cache skills, the `aws-secret-scanner` PreToolUse hook, and the `/aws`, `/aws-spec` commands. Deliberately does NOT include `iac`, `sec`, `iam`, or `cw` — the focus is the FinOps surface.

---

## AWS-200 — give a developer a defensible price ceiling for their feature

**Persona:** A developer asked to add an in-app analytics endpoint and "make sure it doesn't blow the bill."

**Trigger:** "What does it cost to run an in-app analytics endpoint at 50 RPS through API Gateway + Lambda + DynamoDB on-demand for one month, in `us-east-1`?"

**Invocation:**

```text
/aws --quick rough cost ROM for API Gateway + Lambda + DynamoDB on-demand at 50 RPS sustained for 30 days in us-east-1
```

**What happens:**

- The orchestrator classifies the prompt as a verb-of-creation (`rough cost ROM`) and runs full depth.
- `discovery` confirms region, traffic shape, and DynamoDB billing mode via `kb:search_documentation`, seeds `requirements.md`.
- `solution-architect` produces a minimal design and calls `aws-waf-cost-optimization-skill` against it.
- `implementation` calls `cost:get_pricing` for each line item (APIGW HTTP API, Lambda compute + invocations, DynamoDB on-demand reads/writes/storage) and writes `tasks.md` with the ROM table.

**Why this is production-ready:**

- Every ROM line item carries a `cost:<short-key>` citation, so the developer's pull-request reviewer can audit the math instead of trusting a chat transcript.
- The `aws-waf-cost-optimization-skill` 5-step pricing-model decision tree picks DynamoDB on-demand only after the workload is classified against the 10-class workload-eligibility list — no "pick the most flexible knob" defaulting.
- Pricing-pages cache under the `aws-grounding-cache` skill's pricing TTL (30 days), so the next developer asking the same question pays no MCP-call budget.

---

## AWS-300 — design-time right-sizing review with mandatory tagging

**Persona:** A platform owner running a quarterly cost review for a small fleet of services.

**Trigger:** "We have three services on `m5.xlarge` each, ~30% average CPU. Recommend a right-sizing pass and emit the cost-allocation tags we need."

**Invocation:**

```text
/aws --deep right-size three m5.xlarge services at 30% average CPU and produce the cost-allocation tag set that our chargeback model requires
```

**What happens:**

- `discovery` gathers utilisation context and confirms that the workloads are right-sizing candidates per the cost skill's workload-eligibility classes.
- `solution-architect` runs the WAF cost-optimization pillar skill end-to-end: the 5-step pricing decision tree (right-size → pick model → apply tier → commit-discount → continuous monitoring), and surfaces the S3 lifecycle ladder and the Graviton-arm64-default if any of the workloads are container-friendly.
- `implementation` calls `cost:get_pricing` for the proposed instance family (e.g., `c7g.xlarge`) plus the current `m5.xlarge` and writes the variance into the ROM.
- The cost-allocation tag set is produced from the cost skill's mandatory-tags policy: `Environment`, `Owner`, `CostCenter`, `Project`, plus any consumer-specific extension. Tagging is a first-class output, not a rounding error.

**Why this is production-ready:**

- The pricing decision tree is deterministic and ordered. The output's "why we picked X" rationale paragraph maps 1:1 to the tree's step number, so the chargeback reviewer can trace the recommendation back to a known step instead of an opinion.
- The S3 lifecycle ladder explicitly calls out the minimum-storage-duration trap (a real $$$ bug for short-lived objects in IA / Glacier tiers); the recommendation will not silently move data into a tier where the early-deletion fee dominates.
- The `aws-secret-scanner` hook protects the iteration loop: copying a chargeback CSV with embedded API keys will not silently land in the spec directory.

---

## AWS-500 — multi-account RI / SP coverage decision for a regulated workload

**Persona:** A FinOps lead negotiating Reserved Instance / Savings Plan coverage across an organisation with seven accounts, multiple regions, and a regulatory constraint that pins half the fleet to `eu-central-2` (Zurich).

**Trigger:** "We have $1.4M/year of EC2 + Fargate + Lambda spend across 7 accounts and 4 regions, with eu-central-2 fixed for the regulated tenants. Build me a Compute Savings Plan vs Convertible RI vs Standard RI vs Spot recommendation with sensitivity to ±15% workload variance and a one-year horizon. Surface every region where SP / RI inventory is meaningfully thinner than us-east-1."

**Invocation:**

```text
/aws --deep model Compute SP vs Convertible RI vs Standard RI vs Spot for a $1.4M/year EC2+Fargate+Lambda fleet across 7 accounts and 4 regions including eu-central-2, ±15% variance, 1-year horizon, and surface region-by-region SP/RI inventory thinness
```

**What happens:**

- `discovery` calls `kb:search_documentation` against the Savings Plans + RI scope/lifecycle pages and seeds `requirements.md` with the workload class breakdown (steady-state vs variable vs interruptible).
- `solution-architect` runs the WAF cost-optimization skill's pricing-model decision tree per workload class. Steady-state goes to Compute SP, variable goes to On-Demand baseline + variable SP layer, interruptible goes to Spot — each call cited.
- `implementation` calls `cost:get_pricing` per region per family for the candidate commit shapes; the ROM table is built region-by-region. `cost:get_price_list_urls` returns the bulk-pricing CSV/JSON references for any historical sensitivity work the FinOps lead wants to do offline.
- The cost skill calls out tier ladders (Compute SP vs EC2-Instance SP) and the convertibility cost (Convertible RI carries a discount haircut) as Open Questions when the variance band straddles a tier.
- Region-by-region SP/RI inventory thinness is a fact-grounded surface: where `cost:` returns no price for a candidate region/family pair, the design records a `grounding-deferred` marker rather than inventing a number.
- Merge contract: when the security-pillar skill says "do not run regulated tenants outside `eu-central-2`" and the cost-pillar skill says "us-east-1 SP coverage is 12% cheaper," the merge contract resolves security → facts → cost. Cost loses; the rationale paragraph captures why.

**Why this is production-ready:**

- **Auditable ROM under variance.** Every line item in the recommendation table is grounded; sensitivity analysis on ±15% variance is a real arithmetic delta the FinOps lead can replay.
- **Region-thinness honesty.** Where `cost:` cannot answer (e.g., a partial price-list for `eu-central-2`), the spec carries a `grounding-deferred` marker in the design, not an invented number.
- **Mandatory tagging out of the gate.** The output ships with the cost-allocation tag schema (`Environment`, `Owner`, `CostCenter`, `Project`) baked into the recommended IaC; chargeback works on day 1.
- **Conflict resolution is deterministic.** Security wins over cost in any tie; the priority order is asserted, not negotiated mid-meeting.
- **Cache TTL is built for FinOps cadence.** Pricing entries cache for 30 days; the team can rerun the same analysis next month against the live `cost:` server and see only the deltas.
