---
description: Bedrock runtime, IAM, region, and licensing discipline for design and IaC
applyTo:
  - "**/.claude/specs/**/design.md"
  - "**/.claude/specs/**/contracts/*.md"
  - "**/.claude/specs/**/tasks.md"
  - "**/cdk/**/*bedrock*.ts"
  - "**/cdk/**/*bedrock*.py"
  - "**/terraform/**/*bedrock*.tf"
inclusion: conditional
---

- Every Bedrock model reference uses a pinned identifier (`<provider>.<family>-<size>-<variant>:<version>`) confirmed GA in target region(s) via a `kb:get_regional_availability` citation; floating aliases are forbidden in production.
- Per-account, per-region model-access opt-in is documented as an explicit `tasks.md` step before any IaC deployment; absence is a deployment-blocking finding.
- Every invocation principal carries least-privilege IAM (`bedrock:InvokeModel(WithResponseStream)?`, plus `bedrock:Retrieve(AndGenerate)?` or `bedrock-agent-runtime:*`) scoped to the specific model, KB, or agent-alias ARN, with `aws:SourceArn`/`aws:SourceAccount` on cross-service trust.
- Each invocation binds a Guardrail by `guardrailIdentifier` + `guardrailVersion` or carries `no-guardrail` with a documented rationale per `aws-bedrock-prompt`; unfiltered production invocations are forbidden.
- The provider AUP / licence (Anthropic, Meta Llama, Mistral, Cohere, Amazon Nova/Titan, AI21, Stability) is satisfied for the stated use; high-stakes-domain restrictions, attribution, and commercial-vs-community variants surface as Open Questions when ambiguous.
- KMS-CMK is named for every data plane (S3 KB sources, OSS collections, Aurora pgvector, custom-model artefacts, batch buckets); cost ROM line items for tokens, batch discount, provisioned-throughput units, and embedding ingest are grounded by `cost:get_pricing` citations.
