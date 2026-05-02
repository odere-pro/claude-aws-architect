# OE anti-patterns

Loaded on demand by the `aws-waf-operational-excellence-skill`. Catalogue of design-time anti-patterns the skill must surface, with severity guidance.

## How to use this file

For each anti-pattern, scan the artefact for the listed evidence pattern. If found, record a finding with:

- The anti-pattern's identifier (`AP-OE-N`).
- Severity (HIGH / MEDIUM / LOW per the per-pattern guidance).
- Concrete evidence: file path + section + the specific text that matched.

Severity guidance:

- **HIGH**: blocks acceptance; the contract or design cannot transition forward without addressing.
- **MEDIUM**: must be addressed or explicitly deferred with a rationale paragraph in the OE review block.
- **LOW**: noted in the review; does not block transition.

## Anti-pattern catalogue

### Observability and signals

- **AP-OE-1 — TODO observability triple at acceptance.** The contract's Observability section contains `TODO`, `TBD`, or unfilled `<angle-bracket>` tokens. **Severity**: HIGH. The component-contract skill catches this structurally; this skill catches it semantically when the placeholder _was_ replaced with text but the text is not a real signal (e.g., "we'll use CloudWatch", "default Lambda metrics").
- **AP-OE-2 — Single-signal observability.** Only metrics, only logs, or only traces are named. The triple requires all three with a real signal each. **Severity**: HIGH.
- **AP-OE-3 — Unnamed log destination.** Log section says "logs go to CloudWatch Logs" without naming the log group, log stream, or the structured fields. **Severity**: MEDIUM.
- **AP-OE-4 — Unsampled traces in high-volume path.** Trace section names a tracer but does not specify sampling rule on a known high-volume path; traces will be either too sparse to triage or too expensive. **Severity**: MEDIUM.
- **AP-OE-5 — Trace propagation breaks at a boundary without rationale.** A `c4-l2` boundary exists where a trace ID is not propagated, and no rationale explains why (e.g., "this is a fire-and-forget event"). **Severity**: MEDIUM.

### SLOs and SLIs

- **AP-OE-6 — Implicit SLO.** No named latency budget, error rate, or availability target. **Severity**: HIGH on public-facing components, MEDIUM on internal.
- **AP-OE-7 — SLO without SLI.** A latency budget is named but no metric query measures it; the SLO cannot be evaluated. **Severity**: HIGH.
- **AP-OE-8 — SLO copy-pasted from another feature without justification.** Same SLOs as a sibling feature, different traffic profile, no rationale that the choice is still correct. **Severity**: LOW unless the traffic profile is dramatically different.

### Runbooks and failure response

- **AP-OE-9 — Empty runbook reference.** `seq-error` names a failure mode but no runbook is named or linked. **Severity**: HIGH at `accepted` transition; MEDIUM at `draft`.
- **AP-OE-10 — Runbook in a separate, unversioned system.** Runbooks live in a wiki or docs system that does not track which runbook version corresponds to which code version. **Severity**: MEDIUM.
- **AP-OE-11 — No rehearsal cadence for the runbook.** Runbook exists but has never been rehearsed (no game day, no table-top); first execution will be during a real incident. **Severity**: LOW for low-risk components, MEDIUM for high-impact.
- **AP-OE-12 — RTO/RPO undefined for stateful component.** A stateful component (DynamoDB table, RDS, Aurora cluster) without an RTO/RPO. **Severity**: HIGH.

### Organisation and ownership

- **AP-OE-13 — On-call team unspecified.** No named on-call rotation or team for the feature. **Severity**: HIGH.
- **AP-OE-14 — Build team and on-call team distinct, no knowledge-transfer artefact.** The team that built the feature does not own the on-call, and there is no runbook, design walk-through video, or shadowing plan. **Severity**: MEDIUM.
- **AP-OE-15 — Single-owner runbook.** Runbook is owned by one named individual; no fallback owner. **Severity**: LOW (organisational hygiene), unless that individual is the only one who can execute it (then HIGH).

### Deployment and change management

- **AP-OE-16 — Manual deployment.** Deployment is "we'll run terraform apply" or "we'll click Deploy in the console" without a documented runbook. **Severity**: HIGH for production, MEDIUM otherwise.
- **AP-OE-17 — Rollback unspecified.** Deployment strategy named but rollback path is not — only forward fixes are described. **Severity**: HIGH.
- **AP-OE-18 — No canary or progressive deployment for high-impact change.** A change touching high-traffic or revenue-critical components is shipped as a single all-at-once deploy. **Severity**: MEDIUM.
- **AP-OE-19 — IaC and application changes deployed via different pipelines without coordination.** A schema change in IaC must land before the application code that uses the new shape, but no documented coordination exists. **Severity**: MEDIUM.

### Operational telemetry and continuous improvement

- **AP-OE-20 — No SLO trend dashboard.** SLOs are defined but no dashboard tracks them over time; regression goes unnoticed until the on-call gets paged. **Severity**: MEDIUM.
- **AP-OE-21 — No operational review cadence.** No weekly/monthly review of SLOs, incidents, or near-misses. **Severity**: LOW.
- **AP-OE-22 — Log retention shorter than expected investigation window.** A 7-day log retention on a feature whose incidents commonly take 14 days to investigate. **Severity**: MEDIUM.

## What is NOT an anti-pattern (intentional design)

- "We chose 99.9% availability instead of 99.99%" — this is a documented trade-off, not an anti-pattern. The OE review block should _show_ the trade-off rationale (Cost vs Reliability), but the choice itself is legitimate.
- "Logs are at INFO level only on errors" — this is a documented level-discipline choice consistent with the observability triple guidance. Not an anti-pattern.
- "Trace sampling is 1% with 100% on errors" — sampled-with-error-bias is a recognised pattern, not a defect.
