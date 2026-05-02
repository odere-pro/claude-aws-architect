---
name: aws-bedrock-ai
description: |
  **WORKFLOW SKILL** — Amazon Bedrock and AWS AI design: foundation
  model selection, knowledge bases (RAG), agents for bedrock,
  guardrails, provisioned throughput, batch inference, fine-tuning,
  KMS, VPC endpoints, regional GA, and per-provider licensing.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent must reason about, design for, or implement against Amazon Bedrock, AWS AI managed services (SageMaker, Comprehend, Textract, Rekognition, Transcribe, Translate, Polly, Kendra, Amazon Q), or the licensing and data-privacy guarantees that surround foundation models on AWS. Use it whenever the prompt names a Bedrock primitive (foundation model, knowledge base, agent, guardrail, prompt, flow), an inference mode (on-demand, provisioned throughput, batch, cross-region), a fine-tuning surface, or a regulated AI deployment concern.

Trigger conditions:

- The agent must pick a foundation model for a stated workload (latency, context, multimodality, language, cost band).
- The agent must wire a Knowledge Base for Amazon Bedrock (RAG) and decide on the vector store, chunking strategy, and retrieval policy.
- The agent must design an Agents for Bedrock (or AgentCore) flow and define action-group OpenAPI / Lambda contracts.
- The agent must wire Guardrails — content filters, denied topics, sensitive-info filters, contextual-grounding checks — and bind them by ID at invoke time.
- The agent must choose between on-demand, provisioned throughput, batch inference, latency-optimised inference, or cross-region inference profiles, with cost and quota implications.
- The agent must apply licensing or AUP constraints (Anthropic, Meta Llama, Mistral, Cohere, Amazon Nova / Titan, AI21, Stability) before committing a model choice.
- The agent must satisfy a regulated deployment (EU/UK/CA data residency, KMS-CMK at rest, VPC-endpoint-only at transit, no model-training opt-in).

## Procedure

1. **Classify the AI workload.** Pick one of: chat / RAG / agent / batch text / classification / extraction / image / speech / translation / fine-tuned. The category drives model family selection (`references/foundation-models.md`) and the inference mode (`references/inference-modes.md`).
2. **Pick the foundation model and pin the version.** Use the canonical Bedrock model identifier (`<provider>.<family>-<size>-<variant>:<version>`, e.g. `anthropic.claude-sonnet-4-5-20251110-v1:0`). Floating aliases without a version suffix are forbidden in production. Confirm GA in the target region(s) via `kb:get_regional_availability` and `kb:search_documentation` for "Bedrock model availability".
3. **Confirm model access.** Bedrock requires explicit, per-account, per-region model-access opt-in for many providers (Anthropic, Meta, Mistral, Cohere, AI21, Stability, some Amazon models). Document in the design that a console (or `bedrock:PutModelAccessAgreement` equivalent) acceptance step precedes any IaC deployment.
4. **Apply licensing and AUP.** Each provider carries its own EULA layered on top of the AWS Customer Agreement. Check `references/licensing.md` for the per-provider AUP highlights (Anthropic Acceptable Use Policy, Meta Llama Community License + AUP, Mistral commercial terms, Cohere usage policy, Amazon Nova / Titan custom terms, AI21 commercial terms, Stability commercial / community split). Surface any ambiguity as an Open Question in the design rather than picking silently.
5. **Pick the inference mode and quotas.** Apply `references/inference-modes.md`: on-demand for variable, low-volume; cross-region inference profile for capacity smoothing across regions; provisioned throughput for predictable high-RPM with reserved tokens; batch inference for asynchronous bulk jobs (50% pricing discount on supported families); latency-optimised inference for sub-second TTFT on supported models. Cost and quota implications are non-trivial and must land in the cost ROM.
6. **Wire data-privacy and security.** Bedrock does not use customer prompt or completion data to train base foundation models. Always-on guarantee, but the design must still enforce: KMS-CMK encryption for Knowledge Base data sources, S3 buckets, and OpenSearch Serverless collections; VPC endpoints (`com.amazonaws.<region>.bedrock-runtime`, `bedrock`, `bedrock-agent-runtime`, `bedrock-agent`) when the application is VPC-only; no log-group containing prompt bodies without a redaction strategy. Apply `aws-waf-security-skill` for the broader security posture.
7. **Wire IAM least privilege.** A Bedrock invocation principal needs only `bedrock:InvokeModel` (or `InvokeModelWithResponseStream`) plus the resource ARN of the specific model. Knowledge-base callers also need `bedrock:Retrieve` / `RetrieveAndGenerate` and `bedrock-agent-runtime:*` for agents. Guard against confused-deputy with `aws:SourceArn` / `aws:SourceAccount` on cross-service trust policies. Apply `references/iam-patterns.md`.
8. **Wire RAG correctly.** Knowledge Bases for Amazon Bedrock supports OpenSearch Serverless (default), Aurora PostgreSQL with pgvector, Pinecone, Redis Enterprise Cloud, and MongoDB Atlas. Pick per `references/knowledge-bases.md`: OSS for default, Aurora pgvector for VPC-only with existing RDS posture, third-party for existing footprint. Chunking strategy (default, fixed, semantic, hierarchical) and embedding model (`amazon.titan-embed-text-v2:0`, `cohere.embed-english-v3`, `cohere.embed-multilingual-v3`) are explicit decisions in the design.
9. **Wire Guardrails by ID.** A Guardrail is configured separately, versioned, and bound at invoke time via `guardrailIdentifier` + `guardrailVersion`. Content filters (hate, insults, sexual, violence, misconduct, prompt-attack), denied topics, sensitive-info filters (PII regex + denylist), word filters, and contextual-grounding checks compose. The component contract must name the bound guardrail.
10. **Cost ROM via `cost:`.** Bedrock prices are per 1k input tokens and per 1k output tokens; provisioned throughput is per model unit per hour (1 mu = stated tokens/min); batch inference is roughly 50% off on-demand for supported models; cross-region inference profiles add inter-region inference but no extra per-token premium. Knowledge Base storage costs apply on the underlying vector store.

## Gotchas

- **Do not use floating model aliases in production.** Bedrock model IDs without a version suffix can drift. Pin (`anthropic.claude-sonnet-4-5-20251110-v1:0`, not `anthropic.claude-sonnet`) and write a renewal cadence into ops.
- **Do not assume a model is GA in your region.** Bedrock GA varies by provider, family, and feature (e.g., latency-optimised, batch, custom-model-import). Always check `kb:get_regional_availability` for the model+region pair before pinning the design.
- **Do not forget per-account model-access opt-in.** A correctly written IAM policy still fails until model access is granted on the account/region. Document the opt-in step in `tasks.md`.
- **Do not paste prompts containing customer PII into prompt files.** Apply `aws-bedrock-prompt` (which forbids inline secrets, account IDs, region literals, customer IDs) and ensure CloudWatch / S3 logs of prompt bodies use redaction or tokenisation.
- **Do not skip Guardrails on regulated workloads.** Bedrock without a Guardrail is unfiltered. Even when the prompt is internal, contextual-grounding and sensitive-info filters cut PII leakage and prompt-injection blast radius.
- **Do not exceed Bedrock service quotas without a request.** Throttling raises `ThrottlingException`; on-demand quotas are per-account, per-region, per-model. Provisioned throughput quotas are per-account; cross-region inference profiles count against the destination region's quotas.
- **Do not conflate Knowledge Bases for Amazon Bedrock with Amazon Q.** Q Business is a managed end-user assistant; Knowledge Bases for Amazon Bedrock is a developer-facing RAG primitive. Different IAM, different connectors, different pricing.
- **Do not assume Bedrock and SageMaker share IAM scope.** They are separate services with separate IAM principals, separate VPC endpoints, separate model surfaces.
- **Do not log raw model responses for compliance-bound workloads.** Some regulated sectors require model-response retention rules; default CloudWatch logging captures completions, which then enters the audit perimeter.
- **Do not use base-model fine-tuning when distillation or RAG would suffice.** Fine-tuning is expensive (training compute + provisioned-throughput-only inference for the resulting custom model). RAG, prompt engineering, and distillation usually clear the bar at lower cost.

## Boundaries

- This skill MUST NOT bypass the `kb` MCP server for Bedrock documentation. All Bedrock factual claims (region GA, quotas, supported features, model IDs, pricing surfaces) are grounded by `kb:search_documentation` + `kb:read_documentation`, recorded in the grounding ledger.
- This skill MUST NOT recommend a model whose AUP forbids the stated use case. Surface the conflict as an Open Question and let the design make the trade-off explicit.
- This skill MUST NOT design a Bedrock invocation that lacks an IAM least-privilege policy, a region pin, and a guardrail decision (bound or `no-guardrail` with documented rationale).
- This skill MUST NOT invent pricing. Every cost line item is grounded by `cost:get_pricing` against the relevant Bedrock service code.
- This skill MUST NOT design RAG against an unsupported vector store; OSS, Aurora pgvector, Pinecone, Redis Enterprise, MongoDB Atlas are the v0.1.x set.
- This skill MUST NOT bypass `aws-waf-security-skill` for the broader security posture; this skill covers Bedrock-specific concerns, not the entire pillar.

## Quality Checks

Before returning a Bedrock design block, confirm:

- The chosen foundation model is named with a pinned version identifier, GA in the target region(s), and within its provider's licence/AUP for the stated use.
- Per-account, per-region model-access opt-in is documented in `tasks.md`.
- The inference mode (on-demand / provisioned throughput / batch / cross-region inference profile / latency-optimised) matches the workload's RPM, latency, and cost shape.
- KMS-CMK encryption is named for every data plane (S3 sources, OSS collections, Aurora pgvector, custom-model artefacts).
- The IAM principal carries only `bedrock:InvokeModel(WithResponseStream)?` and, where relevant, `bedrock:Retrieve(AndGenerate)?` / `bedrock-agent-runtime:*`, scoped to the specific model and KB ARNs, with `aws:SourceArn` / `aws:SourceAccount` conditions on cross-service trust.
- A Guardrail is bound by ID + version, OR `no-guardrail` carries a documented rationale per `aws-bedrock-prompt`.
- For RAG: the vector store, embedding model, and chunking strategy are explicit in the design, with KMS-CMK on the store and a documented re-index cadence.
- Cost ROM line items are grounded by `cost:get_pricing` citations; batch / provisioned-throughput trade-offs are surfaced when the workload size justifies them.
- Logging strategy for prompt bodies and completions is documented with a redaction policy if the workload is regulated.
- The data-privacy guarantee that Bedrock does not use customer data to train base models is stated, but it does NOT replace KMS, VPC, or IAM controls.
