# Knowledge Bases for Amazon Bedrock — RAG reference

Loaded on demand by the `aws-bedrock-ai` skill. Picks the vector store, embedding model, chunking strategy, and IAM / KMS posture for a Knowledge Bases for Amazon Bedrock deployment.

## Vector-store options (v0.1.x)

| Store                            | When to pick                                                                                                                    | Encryption / network                                                               |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **OpenSearch Serverless (OSS)**  | Default; serverless, autoscaling, AWS-native. Lowest setup friction. Fine for most workloads.                                   | KMS-CMK on the collection; VPC-endpoint policies for VPC-only access.              |
| **Aurora PostgreSQL + pgvector** | Existing RDS posture; VPC-only deployment; SQL co-locality with operational data; multi-tenant filtering by row-level security. | KMS-CMK on the cluster; Aurora-only VPC; pgvector index tuning under the customer. |
| **Pinecone**                     | Existing Pinecone footprint; cross-cloud strategy.                                                                              | Pinecone-managed encryption; private link supported.                               |
| **Redis Enterprise Cloud**       | Existing Redis footprint; cache + vector co-locality.                                                                           | TLS in transit; Redis-managed CMK options.                                         |
| **MongoDB Atlas**                | Existing Atlas footprint; document-shape data + vector search.                                                                  | Atlas-managed encryption; private endpoint to AWS.                                 |

## Embedding model

- Default: `amazon.titan-embed-text-v2:0` (1024 dim).
- Multilingual: `cohere.embed-multilingual-v3` (1024 dim).
- Multimodal: Amazon Titan Multimodal Embeddings.
- Pin the model identifier; re-embed when the model changes; vector dimension cannot mix per index.

## Chunking strategies

| Strategy         | Use when                                                                              | Trade-off                                                               |
| ---------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| **Default**      | Most prose corpora; KB picks chunk size automatically.                                | Loses fine control over context.                                        |
| **Fixed-size**   | Predictable page or paragraph length; legal / regulatory documents.                   | Boundaries can split semantic units.                                    |
| **Semantic**     | Paragraph-shaped sources; better retrieval quality than fixed.                        | More embedding cost during ingest.                                      |
| **Hierarchical** | Long documents (legal, policy) where chunk + parent context both matter at retrieval. | Highest ingest cost; best retrieval relevance for hierarchical content. |

## Data sources

- S3 (most common; supports CSV, JSON, MD, DOCX, HTML, PDF, PPT, TXT). Source bucket needs SSE-KMS with the CMK the KB role can use.
- Confluence, SharePoint, Salesforce, Web Crawler, ServiceNow connectors are first-party in current Bedrock; confirm region GA per source via `kb:`.
- Custom data ingestion via the `IngestKnowledgeBaseDocuments` API for programmatic insert.

## Retrieval and Generate (RAG vs RAG+Generate)

- `Retrieve` returns ranked chunks; the application formats and calls a generative model itself.
- `RetrieveAndGenerate` routes through Bedrock and returns a generated answer + citations in one call.
- `RetrieveAndGenerateStream` adds streaming. Both Generate paths support guardrail bindings via `guardrailConfiguration`.

## IAM posture

A Knowledge Base needs at least three principals:

1. The KB service role (assumed by `bedrock.amazonaws.com`) with `s3:GetObject` on the source bucket(s), `kms:Decrypt` on the source CMK, OSS data-access policy on the collection (or pgvector connection / 3rd-party API key), and `bedrock:InvokeModel` on the embedding model.
2. The application invocation principal (Lambda, ECS, EC2 role) with `bedrock:Retrieve` (or `bedrock:RetrieveAndGenerate`) on the KB ARN, plus `bedrock:InvokeModel` on the generation model when using RAG+Generate.
3. Ingestion job role with `bedrock:StartIngestionJob` and the relevant data-source permissions.

Cross-service trust uses `aws:SourceArn` and `aws:SourceAccount` to defeat confused-deputy patterns.

## Operational discipline

- Re-index cadence is explicit (event-driven on source change, or scheduled). Stale embeddings degrade silently.
- Embedding cost during full re-index is non-trivial; budget via `cost:get_pricing` against the embedding model.
- Vector store storage, query, and sometimes per-million-vector pricing apply on top of Bedrock.
- Guardrail binding at retrieve+generate time blocks PII or denied-topic responses; do not skip in production.
- Citation rendering: `RetrieveAndGenerate` returns chunk-level citations; surface them in the UI to keep human-in-loop possible.
