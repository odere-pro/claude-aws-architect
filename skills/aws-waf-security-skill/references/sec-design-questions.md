# Security design questions

Loaded on demand by the `aws-waf-security-skill`. The questions the architect must answer for the Security pillar at design time. Each question has a documented intent so a missing or hand-waved answer can be flagged.

## How to use this file

For each question:

1. Apply it to the artefact (`design.md` and/or each `contracts/<slug>.md`).
2. Capture the answer — citation, rationale, or "no" — in the Security review block.
3. A missing answer is a finding, not a passing default. Record it as a gap with severity per the checklist.

The questions are grouped by sub-area. The order within a group is intentional: identity and access first (the largest blast-radius decisions), then data protection, then perimeter and detection.

## Identity and access

- **Q-SEC-1.** Who can invoke this feature's public entry points? Cite the IAM authoriser, the resource policy, or the API authentication scheme.
- **Q-SEC-2.** For each IAM role declared, what is the minimum action set the role needs? Are wildcard actions (`*`, `s3:*`) used, and if so, what is the justification?
- **Q-SEC-3.** For each IAM role, what is the resource scope (specific ARNs vs `Resource: "*"`)? Justify any unscoped resource.
- **Q-SEC-4.** Are cross-account roles or trust relationships used? If yes, name the trusted accounts and the rationale.
- **Q-SEC-5.** What is the secret-rotation policy for any long-lived credentials? Where are the secrets stored?
- **Q-SEC-6.** Is permission-boundary or SCP guardrail in effect for the roles? Name the boundary or SCP if so.

## Data protection

- **Q-SEC-7.** For each stateful component, is encryption at rest enabled? Default-managed key (AWS-owned) or customer-managed key (CMK)? Justify the choice.
- **Q-SEC-8.** For each network-traversing channel, is TLS used? What is the minimum version (TLS 1.2 vs 1.3)?
- **Q-SEC-9.** Is data classified (public / internal / confidential / restricted)? What controls map to each class?
- **Q-SEC-10.** Are backups encrypted with the same standard as live data?
- **Q-SEC-11.** What is the data-retention policy? When (and how) is data deleted at end-of-life?

## Identity perimeter and network exposure

- **Q-SEC-12.** Are any S3 buckets, DynamoDB tables, RDS instances, or other stateful resources accessible from the public internet by default? Name and justify any.
- **Q-SEC-13.** For VPC-resident components, what subnets do they live in (public / private / isolated)? What egress rules apply?
- **Q-SEC-14.** Are security groups scoped to specific source CIDRs/SGs, or do they allow `0.0.0.0/0`?
- **Q-SEC-15.** Are VPC endpoints (Interface or Gateway) used for AWS service access from private subnets?
- **Q-SEC-16.** Is an identity-perimeter SCP in effect (e.g., `aws:PrincipalOrgID`)? Name the SCP or note its absence.

## Detection and response

- **Q-SEC-17.** Are GuardDuty findings enabled for the account hosting this feature?
- **Q-SEC-18.** Is Security Hub enabled? Which standards are subscribed (CIS, AWS Foundational, PCI)?
- **Q-SEC-19.** Are CloudTrail data events captured for the data stores in this feature?
- **Q-SEC-20.** What is the alerting path when a Security Hub finding is generated for this feature?
- **Q-SEC-21.** Is there a documented incident-response runbook? (The runbook itself is OE; the _threat scenarios it covers_ are Security.)

## Threat modelling

- **Q-SEC-22.** What is the threat model for this feature? Itemise the top 3–5 threats with their likelihood and impact ratings.
- **Q-SEC-23.** For each top threat, what is the design mitigation?
- **Q-SEC-24.** Are any threats explicitly accepted (no mitigation)? If yes, document the acceptance with sign-off.

## What this section does NOT cover

- Runbooks, on-call rotation, dashboard URLs, deployment rollback — Operational Excellence pillar.
- Multi-AZ, multi-region failover, retry budgets, idempotency design — Reliability pillar.
- Compute selection, caching strategy, load-test plan — Performance Efficiency pillar.
- Cost ceilings, right-sizing, untagged-resource detection — Cost Optimization pillar.
- Region carbon footprint, fleet right-sizing for energy — Sustainability pillar.

If a finding falls into one of those, route it to the corresponding pillar skill rather than absorbing it here.
