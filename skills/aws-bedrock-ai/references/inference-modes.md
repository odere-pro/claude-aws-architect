# Bedrock inference modes — selection reference

Loaded on demand by the `aws-bedrock-ai` skill. Picks the inference mode for a stated workload shape. Confirm the destination model supports the chosen mode via `kb:` before pinning.

## Mode catalogue

| Mode                       | Use when                                                                                                | Pricing shape                                    | Quotas                                                | Latency                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------- | ------------------------------------ |
| **On-demand**              | Variable RPM, unpredictable bursts, lowest commitment.                                                  | Per 1k input + per 1k output tokens.             | Per-account, per-region, per-model RPM and TPM caps.  | Standard model latency; no SLA.      |
| **Cross-region inference** | Capacity smoothing across regions, higher effective quota.                                              | Same per-token pricing; no inter-region premium. | Counts against the _destination_ region's quota.      | Slightly higher TTFT due to routing. |
| **Provisioned throughput** | Predictable high RPM; SLAs; reserved capacity; required for many custom (fine-tuned / imported) models. | Per model unit per hour (1 mu = stated tok/min). | Quota on number of model units per account.           | Stable latency under load.           |
| **Batch inference**        | Asynchronous bulk text jobs; no per-request latency requirement; large input corpora.                   | ≈ 50% off on-demand on supported families.       | Job-size and concurrent-job caps.                     | Hours, not seconds.                  |
| **Latency-optimised**      | Sub-second TTFT requirement on supported tiers; user-facing chat with strict UX latency.                | Premium per-token surcharge.                     | Subset of models / regions; check `kb:` for currency. | Lowest TTFT available on Bedrock.    |

## Decision flow

1. Is the workload **asynchronous** and **batchable** (>=1 hour latency tolerance, >=10k requests / day)? → **Batch inference**, half-price.
2. Is the workload using a **custom-imported** or **fine-tuned** model? → **Provisioned throughput** (often the only option).
3. Does the workload need **stable, predictable latency under sustained high RPM** (>10 sustained TPS, SLA target)? → **Provisioned throughput**.
4. Is the workload **user-facing chat** with **sub-second TTFT** required, on a model that supports it? → **Latency-optimised**.
5. Is the on-demand quota **insufficient** in the primary region but headroom exists in a sibling region? → **Cross-region inference profile**.
6. Otherwise → **On-demand**.

## Quota awareness

- On-demand quotas (RPM, TPM, input-tokens-per-minute, output-tokens-per-minute) are per-account, per-region, per-model. Service Quotas console exposes them; some are adjustable, some hard.
- Provisioned-throughput model-unit quotas are per-account; commit length (`1 month` / `6 month` / `no-commit`) affects price.
- Batch jobs have caps on job size and concurrent jobs per account.
- Cross-region inference profiles count against the destination region's quotas.

## Cost-control patterns

- Cap on-demand spend by per-model service quotas; treat unbounded RPM as an incident.
- For mixed workloads, run latency-sensitive turns on-demand and large reasoning passes via batch.
- Provisioned throughput with a 1-month commit beats on-demand once steady-state TPS clears the break-even threshold (`cost:get_pricing` returns the canonical numbers — do not estimate).
- Cross-region inference profiles solve quota pressure but add inter-region inference latency; for regulated EU workloads, confirm the profile stays within the EU before adopting.
