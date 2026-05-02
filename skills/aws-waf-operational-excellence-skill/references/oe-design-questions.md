# OE design questions

Loaded on demand by the `aws-waf-operational-excellence-skill`. The questions the architect must answer for the Operational Excellence pillar at design time. Each question has a documented intent so a missing or hand-waved answer can be flagged.

## How to use this file

For each question:

1. Apply it to the artefact (`design.md` and/or each `contracts/<slug>.md`).
2. Capture the answer — citation, rationale, or "no" — in the OE review block.
3. A missing answer is a finding, not a passing default. Record it as a gap with severity per the checklist.

The questions are grouped by sub-area. The order within a group is intentional: it walks from the highest-leverage design choices (organisation and on-call) through to the operational specifics (deploy and rollback). Skipping a group because "we'll do it later" is precisely the failure mode this skill exists to surface.

## Organisation and ownership

- **Q-OE-1.** Who is on-call for this feature? Name the rotation or team.
- **Q-OE-2.** What is the escalation path when the primary on-call cannot respond?
- **Q-OE-3.** Which team or individual owns the runbooks, dashboards, and alerting rules for this feature?
- **Q-OE-4.** Is the on-call team distinct from the team that built the feature? If yes, what knowledge-transfer artefact exists?

## Observability and signals

- **Q-OE-5.** For each component, what is the named metric whose threshold breach triggers the on-call page? Cite the metric source.
- **Q-OE-6.** For each component, what structured log fields support a triage walk-through? Name them.
- **Q-OE-7.** Does the trace propagation cross every component boundary in `c4-l2`? Where does it stop and why?
- **Q-OE-8.** What is the dashboard URL or Grafana board the on-call opens first? If none yet, what is the planned location?

## SLOs and SLIs

- **Q-OE-9.** What is the latency budget (p50, p95, p99) per public-facing operation?
- **Q-OE-10.** What is the error-rate budget (per-minute or per-hour error fraction)?
- **Q-OE-11.** What is the availability target (e.g., 99.9% monthly)?
- **Q-OE-12.** How is each SLO measured? Cite the metric query or alarm definition.

## Runbooks and failure response

- **Q-OE-13.** For the dominant failure mode named in `seq-error`, what runbook does the on-call follow? Name or link.
- **Q-OE-14.** Are runbooks versioned alongside the feature code, or in a separate documentation system?
- **Q-OE-15.** What is the rehearsal cadence for the runbook (game day, table-top, none)?
- **Q-OE-16.** What is the recovery time objective (RTO) and recovery point objective (RPO) for this feature?

## Deployment and change management

- **Q-OE-17.** Is the deployment automated (CI/CD)? Name the pipeline or, if manual, the runbook step.
- **Q-OE-18.** What is the rollback strategy? Time to rollback in the worst case?
- **Q-OE-19.** What is the canary or progressive-deployment strategy, if any?
- **Q-OE-20.** Are infrastructure changes (IaC) deployed via the same pipeline as application changes, or separately?

## Operational telemetry and continuous improvement

- **Q-OE-21.** Is there a dashboard tracking the SLOs over time?
- **Q-OE-22.** What is the cadence of operational review (weekly, monthly, none)?
- **Q-OE-23.** How are findings from incidents fed back into the design or runbooks?
- **Q-OE-24.** What is the retention period for the structured logs and traces? Does it cover the longest expected investigation window?

## What this section does NOT cover

- Encryption-at-rest defaults, IAM perimeters, secrets storage — Security pillar.
- Multi-AZ, multi-region, retry budgets, idempotency design — Reliability pillar.
- Compute selection, caching strategy, load-test plan — Performance Efficiency pillar.
- Cost ceilings, right-sizing, untagged-resource detection — Cost Optimization pillar.
- Region carbon footprint, fleet right-sizing for energy — Sustainability pillar.

If a finding falls into one of those, route it to the corresponding pillar skill rather than absorbing it here.
