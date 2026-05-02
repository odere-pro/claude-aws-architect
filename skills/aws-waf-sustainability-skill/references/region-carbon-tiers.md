# Region carbon tiers

Loaded on demand by the `aws-waf-sustainability-skill` skill. Maps AWS regions to a carbon-intensity tier the design-time agent uses for region-selection decisions.

## Source of truth

The authoritative source is AWS's published per-region carbon-intensity figures, refreshed quarterly. The agent must cite the figure via the `aws-spec-grounding` skill's `<server>:<short-key>` format whenever a tier is asserted in a contract or design document.

When the published figure is missing for a newly-launched region, treat the region as **tier-unranked** and emit a `sustainability-advisory` marker per `aws-mcp-routing/references/degraded-modes.md`. Do not infer the tier from marketing copy or third-party estimates.

## Tier table

The tier reflects renewable-energy match plus grid carbon intensity. A region's tier is reviewed every quarter; agents must use the most-recently-cited tier and surface the citation date in the contract.

| Tier   | Definition                                               | Eligible regions (illustrative; verify against the published table)                 |
| ------ | -------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Tier 1 | ≥95% renewable energy match; lowest published gCO2/kWh   | `eu-north-1`, `eu-west-1`, `eu-central-1`, `us-west-2`, `ca-central-1`, `eu-west-3` |
| Tier 2 | 70–95% renewable match; moderate carbon intensity        | `us-east-1`, `us-east-2`, `eu-west-2`, `ap-northeast-1`, `ap-southeast-2`           |
| Tier 3 | <70% renewable match; higher carbon intensity            | regions on grids that are predominantly fossil-fuelled                              |
| Tier U | Tier-unranked (newly launched; figure not yet published) | any region whose figure is missing from the published table                         |

The illustrative columns are guidance for the agent's first decision; the actual tier value at design time is whatever the published figure says, captured at the moment of the call.

## Deviation policy

A workload may legitimately deviate from tier 1 for any of the following reasons. Each deviation must be recorded in the contract's `sustainability:` block with the specific constraint:

- **Data residency** — regulatory requirement to keep data in a specific country (e.g. Brazilian LGPD, German BDSG with a specific-state preference).
- **Latency floor** — the workload's user-facing latency budget excludes any region that is too far from the dominant user population.
- **Service availability** — a required AWS service is not yet generally available in any tier-1 region (rare; verify against the AWS Region table at the time of decision).
- **DR pairing** — primary is in a tier-1 region and DR must be in a paired secondary; the secondary's tier is whatever the pairing dictates.

Cost alone is **not** a legitimate reason to deviate. If a tier-1 region is materially more expensive, that is a cost-pillar discussion; record it as a deviation with the specific cost delta cited from the `cost` MCP.

## Aggregation in the design summary

The orchestrator's merge step computes the per-design summary by counting components per tier:

```text
sustainability:
  region_tier_distribution:
    tier_1: 5
    tier_2: 1
    tier_u: 0
  dominant_tier: tier_1
  deviations:
    - component: dr-replica
      region: ap-southeast-1
      tier: 2
      reason: dr-pairing-requirement
```

This block is the single source of truth the user sees for the system-level region-tier posture; agents must not summarise it in prose elsewhere.
