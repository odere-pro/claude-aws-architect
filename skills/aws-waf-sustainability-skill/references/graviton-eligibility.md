# Graviton eligibility

Loaded on demand by the `aws-waf-sustainability-skill` skill. Defines what counts as a legitimate `requires-x86` rationale and what does not. Graviton (`arm64`) is the design-time default for new compute resources; this reference exists to keep the bypass narrow and verifiable.

## Default

Choose `arm64` instance families (`t4g`, `m7g`, `c7g`, `r7g`, `m8g`, `c8g`) and the corresponding Lambda / Fargate `arm64` runtime. The chosen family is recorded in the contract's `sustainability:` block as `arch: arm64`.

## Legitimate `requires-x86` rationales

Each rationale must be cited in the contract; the agent does not infer eligibility from product names. Verification approach is in parentheses.

- **CUDA / GPU workloads** — NVIDIA's CUDA stack is x86_64 on AWS; ARM CUDA is GPU-instance-specific (verify the requested `g`/`p` family). (Verify by checking the instance family's documented architecture.)
- **Proprietary x86-only binaries** — third-party software the customer is contractually required to run, with no `arm64` build offered by the vendor. (Verify by citing the vendor's release artefacts.)
- **x86-only Java agents / observability shims** — a small set of older APM/profiler agents have no `arm64` build. (Verify by checking the vendor's release matrix.)
- **x86-only Python wheels for niche scientific packages** — some less-popular wheels are not yet built for `manylinux_aarch64`. (Verify by inspecting the package's PyPI release files.)
- **Workload pinned to a non-Graviton instance family by license** — a small number of database engines and commercial software titles are licensed per-core in a way that excludes the Graviton families. (Verify by citing the license terms.)
- **Lift-and-shift with measured ARM regression** — an existing workload whose performance regression on Graviton has been benchmarked and exceeds the SLO. (Verify by citing the benchmark methodology and result; "we tried it once and it felt slow" is not sufficient.)

## Illegitimate rationales

The following do **not** justify a `requires-x86` exception:

- "Graviton is unfamiliar to the team."
- "We've always used `m5`."
- "The CDK example used `m5`."
- "Graviton is cheaper, so we're worried it cuts corners."
- "We don't have time to test."
- "The price-performance gap doesn't seem worth it" — this conflates cost with sustainability; Graviton is a sustainability default, not a cost optimisation.

When the rationale falls into this list, the agent rewrites the contract to `arch: arm64` and notes that the previous `requires-x86` was rejected. The orchestrator does not re-prompt the user for permission; this is a design-time correction.

## Recording the choice

The contract's `sustainability:` block records the decision:

```yaml
sustainability:
  arch: arm64
```

Or, when an exception applies:

```yaml
sustainability:
  arch: x86_64
  requires-x86: cuda-workload
  citation: "vendor:nvidia-cuda-aws-arm-status-2025-q3"
```

The `citation` is the `<server>:<short-key>` reference produced by `aws-spec-grounding`. An exception without a citation is a contract-validation failure.
