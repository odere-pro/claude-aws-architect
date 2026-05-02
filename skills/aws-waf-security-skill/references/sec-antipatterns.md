# Security anti-patterns

Loaded on demand by the `aws-waf-security-skill`. Catalogue of design-time anti-patterns the skill must surface, with severity guidance.

## How to use this file

For each anti-pattern, scan the artefact for the listed evidence pattern. If found, record a finding with:

- The anti-pattern's identifier (`AP-SEC-N`).
- Severity (HIGH / MEDIUM / LOW per the per-pattern guidance).
- Concrete evidence: file path + section + the specific text that matched.

Severity guidance:

- **HIGH**: blocks acceptance; the contract or design cannot transition forward without addressing.
- **MEDIUM**: must be addressed or explicitly deferred with a rationale paragraph in the Security review block.
- **LOW**: noted in the review; does not block transition.

## Anti-pattern catalogue

### Identity and access

- **AP-SEC-1 — Wildcard IAM action at acceptance.** Policy declares `Action: "*"` or service-wildcard like `s3:*` without a justified rationale. **Severity**: HIGH unless explicitly justified for a security-tooling role with documented sign-off.
- **AP-SEC-2 — Wildcard resource at acceptance.** Policy declares `Resource: "*"` outside actions that legitimately require it (e.g., `iam:ListRoles`). **Severity**: HIGH.
- **AP-SEC-3 — Inline policies on roles.** Inline policies attached to roles instead of managed/customer-managed policies; reduces auditability and reusability. **Severity**: MEDIUM.
- **AP-SEC-4 — Long-lived access keys for service-to-service auth.** Access keys used where IAM role assumption (instance profile, IRSA, task role) is available. **Severity**: HIGH.
- **AP-SEC-5 — Trust policy with `Principal: "*"` and a weak condition.** External trust without `aws:SourceAccount`, `aws:SourceArn`, or equivalent constraint. **Severity**: HIGH.
- **AP-SEC-6 — No permission boundary on developer-assumable roles.** Roles assumable by humans without a permission boundary cap. **Severity**: MEDIUM.

### Data protection

- **AP-SEC-7 — Encryption-at-rest unspecified.** Stateful component (S3, DynamoDB, RDS, Aurora, EBS, Secrets Manager, KMS-storing) without an encryption-at-rest decision named. **Severity**: HIGH.
- **AP-SEC-8 — Customer-managed key vs default-managed key not justified.** Encryption is named but the choice between AWS-managed and CMK is unstated; key-rotation control and cross-account access decisions deferred by default. **Severity**: MEDIUM.
- **AP-SEC-9 — TLS version unspecified or below 1.2.** Network channel uses TLS but the version floor is not named, or named as TLS 1.0/1.1. **Severity**: HIGH.
- **AP-SEC-10 — Backup not encrypted.** Live data is encrypted but backup is not, or backup encryption is unstated. **Severity**: HIGH.
- **AP-SEC-11 — Data classification absent.** No classification of the data stored or processed; controls cannot be mapped to sensitivity. **Severity**: MEDIUM.
- **AP-SEC-12 — Indefinite retention.** Data retention is "forever" without a documented business justification. **Severity**: LOW (most cases) to MEDIUM (when GDPR/CCPA/regulatory scope applies).

### Identity perimeter and network exposure

- **AP-SEC-13 — Public-by-default S3 bucket.** Bucket without explicit public-access-block enabled. **Severity**: HIGH.
- **AP-SEC-14 — Public RDS/Aurora endpoint.** Database endpoint reachable from the public internet. **Severity**: HIGH unless explicitly justified.
- **AP-SEC-15 — Security group with `0.0.0.0/0` ingress on a non-public port.** Anything other than HTTPS (443) or HTTP (80) open to the world. **Severity**: HIGH.
- **AP-SEC-16 — No VPC endpoints for AWS service traffic from private subnets.** Traffic to S3/DynamoDB/SQS exits the VPC over the internet gateway when an interface or gateway endpoint would keep it internal. **Severity**: MEDIUM.
- **AP-SEC-17 — No identity-perimeter SCP.** No SCP enforces `aws:PrincipalOrgID`, allowing principals from outside the organisation to assume roles if a trust policy is misconfigured. **Severity**: MEDIUM (organisational-level decision; HIGH if the org owns this and chose not to apply it).

### Detection and response

- **AP-SEC-18 — GuardDuty disabled in account.** No GuardDuty detector in the account hosting this feature. **Severity**: MEDIUM.
- **AP-SEC-19 — Security Hub disabled or no standards subscribed.** Security Hub is on but no standards (CIS, AWS Foundational, PCI) are enabled, so findings are not generated. **Severity**: MEDIUM.
- **AP-SEC-20 — CloudTrail data events not captured for sensitive stores.** S3 data events or DynamoDB data events not enabled for stores containing classified data. **Severity**: MEDIUM.
- **AP-SEC-21 — No alerting path for Security findings.** Security Hub findings are generated but no alarm or notification routes them to the on-call. **Severity**: MEDIUM.

### Threat modelling

- **AP-SEC-22 — Threat model absent.** Security review block has no threat model and no itemised risk list. **Severity**: HIGH.
- **AP-SEC-23 — Threats listed without mitigations.** Threats are itemised but several have empty or hand-waved mitigations. **Severity**: HIGH.
- **AP-SEC-24 — Accepted threat without sign-off.** A threat is documented as "accepted" but no named approver or rationale is recorded. **Severity**: HIGH.

## What is NOT an anti-pattern (intentional design)

- "We chose AWS-managed key for S3 default encryption" — a documented choice with a one-line rationale (e.g., "no cross-account access, no compliance requirement for CMK") is legitimate. Not an anti-pattern.
- "Public-facing API on `0.0.0.0/0:443`" — a public HTTPS endpoint is the _expected_ shape of a public API. Not an anti-pattern; the threat model should still cover its abuse paths.
- "Wildcard action `cloudwatch:GetMetricData` for a monitoring role" — a wildcard at the action prefix that is intrinsically read-only and observability-scoped, with documented rationale, is not an anti-pattern.
