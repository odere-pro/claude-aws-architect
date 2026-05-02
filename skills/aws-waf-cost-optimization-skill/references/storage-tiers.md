# Storage tiers and lifecycle

Loaded on demand by the `aws-waf-cost-optimization-skill` skill. Encodes the storage-tier trade-offs the agent reasons about when authoring lifecycle policies.

## S3 lifecycle defaults

The default lifecycle the agent proposes, unless the workload's retrieval-time SLO forbids:

```text
S3 Standard
  → Standard-IA           after 30 days   (50% cheaper storage; per-GB retrieval cost)
    → Glacier Instant     after 90 days   (~70% cheaper than Standard; ms retrieval)
      → Glacier Deep      after 180 days  (~95% cheaper; 12h retrieval; min 180d)
```

The agent records this exact policy in the contract's `cost:` block and notes any deviations.

## Minimum-storage-duration trap

Glacier tiers carry minimum-storage-duration charges. Deleting an object before the minimum incurs the prorated remaining-day charge:

| Tier                       | Minimum storage | Retrieval-time SLO | Per-retrieval cost |
| -------------------------- | --------------- | ------------------ | ------------------ |
| Standard                   | none            | ms                 | none               |
| Standard-IA                | 30 days         | ms                 | per-GB retrieval   |
| Glacier Instant Retrieval  | 90 days         | ms                 | per-GB retrieval   |
| Glacier Flexible Retrieval | 90 days         | minutes–hours      | per-GB retrieval   |
| Glacier Deep Archive       | 180 days        | 12 hours           | per-GB retrieval   |

Aggressive lifecycle transitions (e.g. Standard → Glacier Deep at day 7) save little on monthly storage but make any retrieval expensive AND incur the 180-day minimum if the object is deleted early. The agent does NOT propose transitions earlier than the minimums above without an explicit rationale citing the workload's actual access pattern.

## Intelligent-Tiering

S3 Intelligent-Tiering is appropriate when access patterns are unpredictable: the service automatically moves objects between frequent-access and infrequent-access tiers based on observed access. There is a small per-object monitoring fee. The agent prefers Intelligent-Tiering over a hand-coded lifecycle when:

- Object access cannot be reasonably predicted by age.
- Object size > 128 KB (smaller objects are excluded from the savings tier and pay the monitoring fee anyway).
- The workload has no strict retrieval-time SLO that would forbid the deeper tiers.

## EBS gp2 → gp3

Default new EBS volumes to **gp3**. gp3 charges separately for capacity, IOPS, and throughput, eliminating the over-provisioning waste that gp2 introduced (where IOPS scaled with capacity). The contract records the requested IOPS and throughput; defaulting to "use gp2 because that's what we did last time" is rewritten by the agent.

## CloudWatch Logs retention

CloudWatch Logs default retention is "Never expire". This is almost always wrong. The agent applies a retention policy on every Log Group:

| Use case                | Default retention          |
| ----------------------- | -------------------------- |
| Application debug logs  | 14 days                    |
| Production access logs  | 90 days                    |
| Audit / compliance logs | per-policy (often 365d–7y) |
| Lambda function logs    | 30 days                    |

The agent applies the shortest of (retention-policy-floor, customer-default, default-above) and records the choice in the contract.

## Storage cost in the design summary

The orchestrator's merge step aggregates per-component storage choices into a system-level summary:

```text
cost:
  storage_summary:
    s3_lifecycle_policies: 5
    intelligent_tiering: 1
    ebs_gp3: 8
    ebs_gp2_legacy: 0
    log_groups_with_retention: 12
    log_groups_default_retention: 0
```

`ebs_gp2_legacy: 0` and `log_groups_default_retention: 0` are the targets; non-zero values are surfaced in `## Open Questions` for the user.

## Anti-patterns

- **Aggressive day-7 transitions** — saves pennies, costs dollars on retrieval and on minimum-duration charges.
- **Unbounded log retention** — the silent monthly bill that grows forever.
- **Snapshot deletion to "save money"** — backups are a separate decision; cost optimisation does not delete them.
- **One-size-fits-all gp3 IOPS** — gp3 lets you provision IOPS independently; the same value across a fleet wastes the model. Provision per workload.
