# Foundation models on Amazon Bedrock — selection reference

Loaded on demand by the `aws-bedrock-ai` skill. Family-level guidance for picking a foundation model on Bedrock. Always confirm GA per region via `kb:get_regional_availability` before pinning a model identifier.

## Model identifier shape

```text
<provider>.<family>-<size>-<variant>:<version>
```

Examples (illustrative; confirm currency via `kb:` before pinning):

```text
anthropic.claude-sonnet-4-5-20251110-v1:0
amazon.nova-pro-v1:0
amazon.nova-lite-v1:0
amazon.titan-embed-text-v2:0
meta.llama3-1-70b-instruct-v1:0
mistral.mistral-large-2407-v1:0
cohere.command-r-plus-v1:0
ai21.jamba-1-5-large-v1:0
stability.stable-image-ultra-v1:1
```

Floating aliases (no version) are forbidden in production.

## Family selection grid

| Workload                                             | First choice (general)                                | Why                                                                                    |
| ---------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Chat / agents / complex reasoning / coding           | Anthropic Claude (Opus / Sonnet / Haiku tiers)        | Strong reasoning + tool-use; long context; broad provider support across regions.      |
| Cost-sensitive chat / classification / extraction    | Amazon Nova (Pro / Lite / Micro)                      | Native AWS pricing; lower per-token cost; good extraction and classification.          |
| Open-weights flexibility / on-prem-comparable        | Meta Llama 3.x family                                 | Llama Community Licence; broad ecosystem; runnable on SageMaker for on-prem-style ops. |
| Multilingual / European-heavy                        | Mistral Large / Mixtral                               | Strong multilingual; permissive commercial terms.                                      |
| Enterprise RAG with rerank / multilingual embeddings | Cohere Command R+ + Cohere Embed v3                   | Tight RAG integration; multilingual embeddings.                                        |
| Long context tasks (legal, finance corpora)          | AI21 Jamba family                                     | Mamba/Transformer hybrid optimised for very long context.                              |
| Image generation                                     | Stability Stable Image Ultra / Core                   | Highest fidelity image generation on Bedrock.                                          |
| Image / video understanding                          | Anthropic Claude vision tiers, Amazon Nova multimodal | Strong vision + reasoning; pick by region GA.                                          |
| Embeddings (text)                                    | Amazon Titan Embed Text v2 (default), Cohere Embed v3 | Titan v2 is the AWS-native default; Cohere v3 for multilingual or large-tenant RAG.    |
| Embeddings (image / multimodal)                      | Amazon Titan Multimodal Embeddings                    | First-party multimodal embedding family.                                               |

## Decision drivers

1. **Region GA.** Some families lag in `eu-central-2`, `me-south-1`, `ap-south-2`, etc. Use `kb:list_regions` + `kb:get_regional_availability`.
2. **Per-provider AUP / licence.** See `references/licensing.md`. Llama 3.x is Llama Community Licence; Mistral and Cohere have their own commercial terms; Amazon Nova / Titan run under the AWS Customer Agreement and Service Terms.
3. **Inference mode support.** Not every model supports batch inference, latency-optimised inference, custom model import, or cross-region inference profiles. Confirm in the docs page for the family.
4. **Context window and modality.** Match the largest reasonable context to your workload; do not over-buy when a smaller tier clears the bar.
5. **Cost band.** Get on-demand input/output token prices via `cost:get_pricing` for the specific model. Provisioned throughput pricing is per model unit per hour.

## Embeddings choice — quick rule

- Default: `amazon.titan-embed-text-v2:0` (1024 dimensions, English-strong, AWS-native).
- Multilingual / European: `cohere.embed-multilingual-v3` (1024 dim).
- Multimodal (text + image): Amazon Titan Multimodal Embeddings.
- Pin the embedding model version. Re-embed when you change it; the vector store cannot mix dimensions.

## What this reference is not

A live model catalogue. Bedrock adds, deprecates, and re-tiers models continuously. Always re-ground via `kb:` before committing a design. The grounding ledger entry expires under the `api-shape` TTL class for model identifiers.
