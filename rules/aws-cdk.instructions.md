---
description: AWS CDK construct, stack, and prop hygiene
applyTo:
  - "**/lib/**/*.ts"
  - "**/bin/**/*.ts"
  - "**/cdk.json"
  - "**/cdk.context.json"
  - "**/*.stack.ts"
  - "**/*.construct.ts"
inclusion: conditional
---

- Construct identifiers are PascalCase, end in the kind they wrap (`Bucket`, `Function`, `Table`), and remain stable across renames so logical IDs do not churn.
- Each stack covers one cohesive deployment boundary; cross-stack references go through `CfnOutput`/SSM-parameter exports rather than direct construct imports across stack boundaries.
- Construct prop interfaces are read-only at the type level, accept primitive or AWS-CDK types only, and never accept open-ended `any`/`object` payloads.
- Removal policies are explicit on every stateful resource (S3, DynamoDB, RDS, KMS, Secrets Manager); the default of `RETAIN` for production and `DESTROY` for ephemeral environments is named in the construct, not inherited.
- Environment is bound explicitly via `env: { account, region }`; no construct relies on `process.env.CDK_DEFAULT_*` at synth time without a documented fallback.
- Inline IAM JSON is forbidden in CDK; use `iam.PolicyStatement` and `iam.ManagedPolicy` so least-privilege analysis can lint the policy. Apply `aws-iam-policy` and `aws-component-contract` skills.
