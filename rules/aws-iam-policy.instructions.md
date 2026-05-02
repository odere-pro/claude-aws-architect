---
description: AWS IAM policy least-privilege and ARN scoping
applyTo:
  - "**/iam/**/*.json"
  - "**/policies/**/*.json"
  - "**/*.policy.json"
  - "**/*-policy.json"
inclusion: conditional
---

- Action lists are minimal and explicit; wildcard actions (`*`, `service:*`) appear only on read-only operations or with a documented sign-off in the matching component contract's Acceptance criteria.
- Resource ARNs are scoped to specific identifiers; `Resource: "*"` is allowed only for actions that intrinsically require it (e.g., `iam:ListRoles`, `cloudwatch:GetMetricData`) and the rationale is recorded inline.
- Required condition keys are present on actions that support them: `aws:SourceArn`, `aws:SourceAccount`, `aws:PrincipalOrgID`, `aws:RequestedRegion`, `aws:ResourceTag/<key>`, depending on the call surface.
- Trust policies (`AssumeRolePolicyDocument`) never use `Principal: "*"`. External principals carry both an account constraint and at least one of `aws:SourceArn` or `aws:SourceAccount` in the condition block.
- Deny statements are reserved for guardrails (data-residency, exfiltration, untagged-resource creation); they are not used as a substitute for missing allows.
- Policies do not embed account IDs, region literals, or resource names that should be templated; consumers parameterise via the calling stack. Apply `aws-waf-security-skill`.
