# Security checklist

Loaded on demand by the `aws-waf-security-skill`. End-to-end checklist for the Security pillar at design time. Each item is satisfied with evidence, deferred with rationale, or flagged as a gap.

## How to use this checklist

For each item below:

1. Mark **PASS** with the evidence (file path + section, or citation).
2. Mark **DEFER** with a one-paragraph rationale (why this is OK to ship without satisfying).
3. Mark **GAP** when neither — the Security review block lists every GAP with severity.

The checklist is intentionally exhaustive at the cost of redundancy with `sec-design-questions.md` and `sec-antipatterns.md`. The questions are open-ended; the anti-patterns scan for known shapes; this checklist is the final pre-acceptance gate.

## Identity and access

- [ ] **SECC-1.** All public entry points have an authenticated/authorised path documented (IAM authoriser, resource policy, API auth scheme).
- [ ] **SECC-2.** Every IAM role has a minimum-action analysis recorded. Wildcard actions justified with sign-off (severity per `AP-SEC-1`: HIGH unless explicitly justified).
- [ ] **SECC-3.** Every IAM role has a resource-scope analysis recorded (`Resource: "*"` justified per case).
- [ ] **SECC-4.** Cross-account trust relationships are named, with trusted accounts and rationale.
- [ ] **SECC-5.** Long-lived credentials replaced with role-assumption where AWS supports it (instance profile, IRSA, task role).
- [ ] **SECC-6.** Permission boundaries or SCPs in effect for human-assumable roles.

## Data protection

- [ ] **SECC-7.** Every stateful component has encryption-at-rest decision named (default-managed key vs CMK with rationale).
- [ ] **SECC-8.** Every network-traversing channel names a TLS version floor ≥ 1.2.
- [ ] **SECC-9.** Data is classified (public / internal / confidential / restricted).
- [ ] **SECC-10.** Backups encrypted at the same standard as live data.
- [ ] **SECC-11.** Data-retention policy named, with end-of-life deletion mechanism.

## Identity perimeter and network exposure

- [ ] **SECC-12.** No stateful resource is public-by-default (S3 public-access-block enabled; database endpoints not internet-reachable, or explicitly justified).
- [ ] **SECC-13.** VPC-resident components named subnet tier (public/private/isolated) and egress rules.
- [ ] **SECC-14.** Security groups scoped to specific source CIDRs/SGs (no `0.0.0.0/0` ingress on non-public ports).
- [ ] **SECC-15.** VPC endpoints used for AWS service traffic from private subnets where applicable.
- [ ] **SECC-16.** Identity-perimeter SCP (`aws:PrincipalOrgID` or equivalent) named or its absence explicitly accepted at the org level.

## Detection and response

- [ ] **SECC-17.** GuardDuty enabled in the account hosting this feature.
- [ ] **SECC-18.** Security Hub enabled with at least one standard subscribed (CIS / AWS Foundational / PCI).
- [ ] **SECC-19.** CloudTrail data events captured for sensitive stores.
- [ ] **SECC-20.** Alerting path documented for Security Hub findings on this feature.

## Threat modelling

- [ ] **SECC-21.** Threat model present: top 3–5 threats with likelihood and impact ratings.
- [ ] **SECC-22.** Each top threat has a design mitigation named.
- [ ] **SECC-23.** Accepted threats carry a named approver and rationale.

## Cross-pillar boundary

- [ ] **SECC-24.** Findings clearly belonging to other pillars (Operational Excellence, Reliability, Performance Efficiency, Cost, Sustainability) have been routed to the corresponding pillar skill rather than absorbed here.

## Final synthesis

- [ ] **SECC-25.** Security review block in `design.md` follows the template structure and lists every GAP with severity (HIGH / MEDIUM / LOW).
- [ ] **SECC-26.** Each HIGH gap is either resolved or has an explicit, time-bounded deferral rationale (e.g., "post-launch milestone, week 2").
- [ ] **SECC-27.** No HIGH gap remains for any contract whose status is being transitioned to `accepted` or `implemented`.

## Severity rollup for the review block

The review block summarises the checklist outcome as:

- **HIGH gaps**: count + list. These block transition.
- **MEDIUM gaps**: count + list. These should be addressed pre-launch.
- **LOW gaps**: count + list. These are noted for follow-up.
- **DEFER items**: count + summary. These are accepted ships-without-satisfying with documented rationale.

A review block with non-zero HIGH gaps and no explicit deferral for each is a failed Security review.
