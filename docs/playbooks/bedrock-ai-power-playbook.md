# `claude-aws-architect-bedrock-ai` — playbook

Amazon Bedrock + AWS AI domain power. Bundles `kb`, `cost`, `iam`, `sec` MCP servers; the `aws-bedrock-ai` skill; the substrate routing / grounding / cache skills; the component-contract skill; the WAF security pillar skill; both default PreToolUse hooks; and `/aws`, `/aws-spec`, `/aws-doctor`, `/aws-kb`.

> See [`skills/aws-bedrock-ai/SKILL.md`](../../skills/aws-bedrock-ai/SKILL.md) for the underlying procedure, the foundation-model selection grid, the inference-mode catalogue, the licensing snapshot, the knowledge-base reference, and the IAM patterns.

---

## AWS-200 — first call to a Bedrock model from a Lambda

**Persona:** A developer building an internal tool that summarises support tickets.

**Trigger:** "I want to call Claude on Bedrock from a Lambda. What model do I pin, what IAM does the Lambda role need, and what do I do about model access?"

**Invocation:**

```text
/aws-kb --onboard Amazon Bedrock InvokeModel
```

then

```text
/aws --quick design a Lambda that calls Anthropic Claude on Bedrock in eu-west-1, with a guardrail bound by ID, KMS-CMK on logs, and the IAM least-privilege policy for the execution role
```

**What happens:**

- `/aws-kb` returns a five-section onboarding pass: what InvokeModel does, the request/response shape, the model-access opt-in flow, citations to the AWS docs, related topics (Guardrails, model evaluation), and `Next` steps.
- `/aws --quick` (which the orchestrator escalates to full depth on the `design` verb) runs the SDLC fan-out:
  - `discovery` calls `kb:get_regional_availability` to confirm the chosen Anthropic model identifier is GA in `eu-west-1` and seeds `requirements.md`.
  - `solution-architect` runs `aws-bedrock-ai` to pin the model identifier (`anthropic.claude-…-v1:0`), wire the Guardrail binding by ID + version, and write a component contract for the Lambda + the model + the guardrail.
  - `implementation` writes the Lambda execution-role IAM policy with `bedrock:InvokeModel` scoped to the foundation-model ARN, plus `aws:SourceAccount` on the trust, and `tasks.md` lists the explicit per-account / per-region model-access opt-in step.

**Why this is production-ready:**

- The model-access opt-in step is captured in `tasks.md` — the `aws-bedrock-ai` rule makes its absence a deployment-blocking finding instead of a silent runtime failure.
- The IAM policy is scoped to the specific model ARN, not `Resource: "*"`. The `aws-waf-security-skill` (loaded by the Power) flags wildcards as anti-patterns.
- The Guardrail is bound by `guardrailIdentifier` + `guardrailVersion`; unbound production invocations fail the rule.
- Every region / model / IAM claim carries a `kb:` or `iam:` citation in the grounding ledger.

---

## AWS-300 — Knowledge Bases for Amazon Bedrock with full security review

**Persona:** A senior engineer building a RAG-backed support assistant on top of an existing S3 knowledge corpus.

**Trigger:** "Build a Knowledge Base for Amazon Bedrock against our `s3://kb-prod-corpus` bucket, generate answers with Claude Sonnet, enforce a Guardrail that blocks PII responses and out-of-scope topics, and run the security pillar end-to-end against the design."

**Invocation:**

```text
/aws --deep design a Knowledge Base for Amazon Bedrock over s3://kb-prod-corpus with OpenSearch Serverless, amazon.titan-embed-text-v2:0, semantic chunking, KMS-CMK on the source bucket and the OSS collection; generate with Anthropic Claude Sonnet via RetrieveAndGenerate, bound to a Guardrail that blocks PII and a denied-topic list; full WAF security pillar review on the result
```

**What happens:**

- `discovery` populates `requirements.md`, calls `kb:search_documentation` for KB-for-Bedrock concepts (vector store options, chunking strategies, embedding-model defaults) and `kb:get_regional_availability` for the chosen Sonnet identifier and the OSS feature.
- `solution-architect` runs `aws-bedrock-ai` end-to-end: vector store = OSS, embedding model = `amazon.titan-embed-text-v2:0` pinned, semantic chunking, KMS-CMK on the source bucket and the OSS collection, the KB service role + the application invocation role + the ingestion-job role each scoped per the IAM patterns reference. Guardrail config is written: PII filter (regex + denylist), denied-topic list, contextual-grounding check.
- `solution-architect` also runs the `aws-waf-security-skill` against the design — 24 questions covering identity, encryption, network, threat detection, IR — and emits findings tagged with severity. `sec:CheckStorageEncryption` confirms the S3 bucket and OSS collection are CMK-encrypted at rest; `sec:CheckNetworkSecurity` verifies the VPC endpoints (`com.amazonaws.<region>.bedrock-runtime`, `bedrock-agent-runtime`) are deployed.
- `implementation` writes the IaC (CDK or Terraform) and the ingestion-job kickoff. `iac:check_cloudformation_template_compliance` runs cfn-guard rules; the `aws-secret-scanner` and `aws-api-write-guard` hooks remain active throughout.

**Why this is production-ready:**

- **Vector-store decision is explicit, not assumed.** OSS is named with rationale (default, serverless, AWS-native); the Aurora pgvector / Pinecone / Redis / MongoDB alternatives are surfaced under "Alternatives considered" so the reviewer sees the trade-off.
- **Embedding model is pinned and documented for re-embedding.** Changing the embedding model requires a re-index; the design captures the cadence.
- **Guardrail is bound, not optional.** `RetrieveAndGenerate` carries `guardrailConfiguration` with the explicit ID + version. The PII filter on responses is independent of the prompt's request — even if the prompt asks for PII, the guardrail blocks the response.
- **WAF security pillar is run with closed anti-pattern lists.** The 24 anti-patterns and 27 checklist items are asserted; gaps surface as findings the engineer must clear.
- **Citations land in the grounding ledger.** The reviewer can re-derive every choice (vector store, embedding model, chunking) months later via `.grounding-ledger.json`.

---

## AWS-500 — multi-region Bedrock with EU data residency, provisioned throughput, and model-evaluation policy

**Persona:** A staff architect deploying a regulated EU-only AI assistant. Workload mixes high-RPM user-facing chat and overnight batch summarisation. Compliance requires that no Bedrock inference leaves the EU; FinOps requires a defensible cost ROM versus on-demand; legal requires a model-evaluation runbook executed before any model identifier change.

**Trigger:** "Deploy a Bedrock-backed assistant across `eu-west-1` (primary) and `eu-central-1` (fallback). User-facing chat: target P95 TTFT 800ms, sustained 30 RPS, latency-optimised on supported tiers. Overnight batch: 200k summarisations / day, 50% batch-pricing discount when supported. RAG against EU-resident corpus (KMS-CMK, VPC-only). Cross-region inference profile must stay in the EU. Provisioned throughput vs on-demand modelled with break-even. Model-evaluation runbook required for any model identifier change. Surface every place we are non-compliant with our data perimeter."

**Invocation:**

```text
/aws --deep design a multi-region Bedrock assistant in eu-west-1 (primary) and eu-central-1 (fallback) with EU-only cross-region inference profile, latency-optimised inference for chat at P95 TTFT 800ms and 30 RPS sustained, batch inference for 200k overnight summarisations, RAG against an EU-resident corpus on KMS-CMK with VPC-only OSS, provisioned throughput vs on-demand cost model with break-even, model-evaluation runbook gating model identifier changes, full data-perimeter security review
```

**What happens:**

- `discovery` calls `kb:get_regional_availability` for every chosen model+region+feature triple (latency-optimised inference, batch inference, cross-region inference profile, KB-for-Bedrock with OSS) — each one a separate ledger entry. Anything that fails GA in `eu-central-1` surfaces as an Open Question; `discovery` does not invent capacity.
- `solution-architect` runs `aws-bedrock-ai` and produces the inference-mode plan: latency-optimised on the chat path (premium per-token surcharge), batch on the summarisation path (~50% off on supported families), provisioned throughput on the steady-state baseline once `cost:get_pricing` clears the break-even threshold. Cross-region inference profile is restricted to a profile whose destination regions are both in the EU; the rule asserts that the profile ARN is verified against a `kb:` citation, not assumed.
- `solution-architect` runs the WAF security pillar end-to-end and the `aws-bedrock-ai` skill's regulated-deployment posture: KMS-CMK on every Bedrock data plane (S3 sources, OSS collections, batch input/output buckets, custom-model artefacts), VPC endpoints per service (`bedrock-runtime`, `bedrock`, `bedrock-agent-runtime`, `bedrock-agent`), SCPs requiring `aws:PrincipalOrgID` on `bedrock:*`, VPC endpoint policies pinning the same. Findings are severity-tagged.
- `solution-architect` writes the model-evaluation runbook as a contract: every model-identifier change goes through a Bedrock model-evaluation job (or external eval suite) with a fixed golden set, pass thresholds, and a documented rollback path — bound to the `aws-bedrock-prompt` rule's evaluation-hook requirement.
- `implementation` builds the IaC and the cost ROM. `cost:get_pricing` is called per region, per inference mode, per model; provisioned-throughput break-even is computed against sustained RPM. The variance band (peak vs trough) is captured; if the on-demand cost dominates the provisioned-throughput cost only above a sustained 25 RPS threshold, the design uses on-demand below the threshold and provisioned above, with a documented switch-over signal.
- The merge contract resolves any disagreement: security ("data perimeter requires SCP-blocked egress to non-EU regions") wins over cost ("us-east-1 has cheaper SP coverage") and over convergence ("the team prefers a single region to keep ops simple"). The rationale is visible in the design.
- `iam:simulate_principal_policy` validates the application invocation role against the foundation-model ARN, the KB ARN, and the inference-profile ARN. `sec:GetSecurityFindings` is queried for any pre-existing GuardDuty / Security Hub findings against the deployment accounts.

**Why this is production-ready:**

- **Region GA is fact-grounded for every feature.** Latency-optimised inference, batch inference, cross-region inference profiles, and KB-for-Bedrock features each carry their own region GA citation. A regulator can trace why `eu-central-1` was treated as a fallback rather than co-primary.
- **Inference-mode cost is mathematical, not vibes.** The break-even between on-demand, provisioned throughput, and batch is computed from `cost:get_pricing` against the workload's sustained RPM and bulk volume. FinOps replays the calculation against next month's usage.
- **Data perimeter is mechanical.** SCPs, VPC endpoint policies, and resource-based policies are written. The design enumerates every place a principal could egress to a non-EU region; the security pillar marks any uncovered path as a finding.
- **Model-evaluation gating is contractual.** No model-identifier change ships without the eval-job pass. This caps the blast radius of provider model deprecations / re-tiers.
- **Licensing is explicit.** The chosen Anthropic / Amazon Nova / Mistral / Cohere model carries a citation against its provider's AUP, and any high-stakes-domain restrictions (legal advice, medical advice) are surfaced as Open Questions for the regulated tenants.
- **No silent throttle.** `ThrottlingException`, `ServiceQuotaExceededException`, and `ModelTimeoutException` map to distinct retry / circuit-break paths in the application; the design names which signal triggers which behaviour.
- **Hooks stay on under regulated load.** `aws-secret-scanner` blocks any inadvertent paste of guardrail-bypass prompts containing customer data; `aws-api-write-guard` blocks any `aws bedrock create-model-customization-job` write verb the implementation specialist might emit, ensuring fine-tuning kicks off through change management, not through the chat session.
