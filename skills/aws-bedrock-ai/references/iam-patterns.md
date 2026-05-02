# Bedrock IAM patterns — reference

Loaded on demand by the `aws-bedrock-ai` skill. Least-privilege patterns for Bedrock invoke, knowledge-base, agent, and guardrail surfaces.

## Invoke a foundation model (chat / completion)

```text
Action:   bedrock:InvokeModel
          bedrock:InvokeModelWithResponseStream  (when streaming)
Resource: arn:aws:bedrock:<region>::foundation-model/<provider>.<family>:<version>
          arn:aws:bedrock:<region>:<account>:inference-profile/<profile-id>   (cross-region)
Conditions:
  - bedrock:GuardrailIdentifier  (force a guardrail at invoke time, optional)
```

Forbid `Resource: "*"` on `bedrock:InvokeModel*` outside of explicit broad-discovery roles.

## Cross-region inference profile

Inference profile ARNs (`arn:aws:bedrock:<dest-region>:<account>:inference-profile/<id>`) replace the foundation-model ARN at invoke time. Quotas count against the destination region. The IAM principal needs the inference-profile ARN as the resource.

## Custom / fine-tuned / imported model

```text
Action:   bedrock:InvokeModel
Resource: arn:aws:bedrock:<region>:<account>:custom-model/<base-model>/<custom-model-id>
          arn:aws:bedrock:<region>:<account>:provisioned-model/<provisioned-id>
```

Custom models on Bedrock are typically invoked via a provisioned-throughput model ARN (provisioning is not optional for many fine-tuned families).

## Knowledge Base — Retrieve / RetrieveAndGenerate

```text
Action:   bedrock:Retrieve
          bedrock:RetrieveAndGenerate
          bedrock:RetrieveAndGenerateStream
Resource: arn:aws:bedrock:<region>:<account>:knowledge-base/<kb-id>
          arn:aws:bedrock:<region>::foundation-model/<gen-model>     (RAG+Generate)
```

The KB service role itself needs:

```text
Action:   bedrock:InvokeModel  (embedding model)
          s3:GetObject, s3:ListBucket  (source bucket scoped)
          kms:Decrypt          (source CMK)
          aoss:APIAccessAll    (OSS) or pgvector connection / 3rd-party secret
Trust:
  Principal: bedrock.amazonaws.com
  Conditions: aws:SourceArn = <kb-arn>, aws:SourceAccount = <account>
```

## Agent for Bedrock / AgentCore

```text
Action:   bedrock-agent-runtime:InvokeAgent
          bedrock-agent-runtime:Retrieve
          bedrock-agent-runtime:RetrieveAndGenerate
Resource: arn:aws:bedrock:<region>:<account>:agent-alias/<agent-id>/<alias-id>
```

Agent service role:

```text
Action:   bedrock:InvokeModel  (orchestration model)
          lambda:InvokeFunction  (action group Lambdas, scoped per ARN)
          bedrock:Retrieve  (associated KB)
Trust:
  Principal: bedrock.amazonaws.com
  Conditions: aws:SourceArn matches the agent ARN
```

## Guardrails

```text
Action:   bedrock:ApplyGuardrail   (standalone application of a guardrail)
          bedrock:GetGuardrail     (read configuration)
Resource: arn:aws:bedrock:<region>:<account>:guardrail/<guardrail-id>
```

Bind a guardrail at invoke time via `guardrailIdentifier` + `guardrailVersion` on the InvokeModel / RetrieveAndGenerate request; the IAM policy must allow the foundation-model resource to be invoked under that guardrail.

## Throttle / quota signal

`ThrottlingException`, `ServiceQuotaExceededException`, and `ModelTimeoutException` are the three runtime signals that map to quota / capacity. Application code distinguishes them; retry strategy differs (exponential backoff for throttling; circuit-break for capacity).

## Data-perimeter posture

For an org with a data perimeter:

- SCP that requires `aws:PrincipalOrgID` on calls to `bedrock:*`.
- VPC-endpoint policy that allows only `aws:PrincipalOrgID` and the specific roles.
- Resource-based policies (where applicable, e.g., custom-model-import S3 buckets) require `aws:ResourceOrgID`.

This matches the WAF security pillar's data-perimeter pattern; surface gaps as findings, not warnings.
