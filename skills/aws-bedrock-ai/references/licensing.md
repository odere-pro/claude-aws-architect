# Bedrock foundation-model licensing — reference

Loaded on demand by the `aws-bedrock-ai` skill. Per-provider AUP / licence highlights. Each provider's terms layer on top of the AWS Customer Agreement and AWS Service Terms.

> This file is not a legal review. It is a routing checklist that flags where to look before committing a model choice. Always re-ground via `kb:search_documentation` ("acceptable use policy", "<provider> licence", "Bedrock service terms") and surface ambiguity as an Open Question.

## Per-provider snapshot

| Provider     | Licence shape                                             | Highlight constraints to verify                                                                                                                                                                                                                                                                   |
| ------------ | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Anthropic    | AWS Service Terms + Anthropic Acceptable Use Policy (AUP) | Prohibited categories (CSAM, weapons, self-harm content, election manipulation, mass-casualty bio/chem/nuclear/radiological assistance). Restrictions on high-stakes use (medical / legal / financial advice without human review). Prompt-injection resilience is the customer's responsibility. |
| Meta (Llama) | Llama Community Licence + AUP                             | Allows commercial use. Attribution required ("Built with Meta Llama"). Restrictions above named user thresholds in some Llama versions. Llama AUP forbids weaponization, mass surveillance, defamation, and a list of high-risk categories.                                                       |
| Mistral      | Mistral commercial / open-weights split                   | Some weights are Apache-2.0 (Mistral-7B, Mixtral 8x7B); larger / instruct variants on Bedrock are commercial. Confirm which variant the model identifier maps to.                                                                                                                                 |
| Cohere       | Cohere usage policy + commercial terms                    | No re-distribution of model weights or fine-tuning artefacts outside the customer's accounts. Restrictions on competitive-evaluation use.                                                                                                                                                         |
| Amazon       | AWS Customer Agreement + AWS Service Terms (Bedrock)      | Amazon Nova / Titan run under standard AWS terms. AWS commits that customer prompt + completion data is not used to train base FMs. Customer-managed CMK key options for Bedrock data planes. Commercial use is in-scope for all Amazon-published Bedrock models.                                 |
| AI21         | AI21 commercial terms                                     | Jamba family; commercial use permitted. Confirm restrictions on content category and high-risk use.                                                                                                                                                                                               |
| Stability    | Stability commercial / community licence split            | Some Stable Image variants on Bedrock are commercial-only; Stable Image Core / Ultra / Diffusion models have separate terms. Image-generation outputs may carry attribution or training-data limitations depending on the variant.                                                                |

## Cross-cutting AWS Bedrock guarantees (verify currency via `kb:`)

- Bedrock does NOT use customer prompt or completion data to train base foundation models. (Always-on guarantee.)
- Customer data is encrypted in transit (TLS) and at rest (AWS-managed KMS by default; CMK opt-in available on the data planes that support it: KB sources, OSS collections, custom-model artefacts, batch input/output S3).
- Per-account, per-region model-access opt-in is a separate consent step that takes effect against the AWS account. Some models require additional eligibility (e.g., regulated workload programs).
- No-training opt-in for Amazon-published models is the default; customer may not be required to opt-out anywhere because base models are not trained on customer data.

## Application checklist

- [ ] Foundation model identifier resolves to a provider whose AUP allows the stated use case.
- [ ] Attribution requirement (Llama "Built with Meta Llama") satisfied in the consumer-facing surface, where applicable.
- [ ] Commercial-use bar cleared for the specific model variant (Mistral / Stability commercial vs community).
- [ ] Restrictions on high-stakes domains (medical / legal / financial) explicitly addressed in the design (human-in-loop, disclaimers, scope limits).
- [ ] Data-residency expectation matches the region-pinned design; no cross-region inference profile crosses an unsupported boundary.
- [ ] Customer-supplied training data for fine-tuning carries the customer's right to use it for that purpose.
- [ ] Output-attribution requirements (some image families) reflected in the consumer flow.

Surface unresolved licensing questions as `## Open Questions` entries in `design.md`. Never silently pick a model whose AUP conflicts with the use case.
