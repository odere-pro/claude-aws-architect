# Contract schema

Loaded on demand by the `aws-component-contract` skill. Defines the exact shape of a per-component contract file at `.claude/specs/<feature>/contracts/<slug>.md`.

## File path

```text
.claude/specs/<feature>/contracts/<slug>.md
```

- `<feature>` is the feature directory; lowercase-kebab-case.
- `<slug>` is the component identifier; lowercase-kebab-case, ≤50 chars, regex `^[a-z][a-z0-9-]*[a-z0-9]$`.
- One file per component. Multiple components per feature live as siblings under the same `contracts/` directory.

## Frontmatter

YAML frontmatter, exactly the following keys:

| Key           | Type     | Required | Allowed values / format                                                                        |
| ------------- | -------- | -------- | ---------------------------------------------------------------------------------------------- |
| `component`   | string   | yes      | The component slug. Must match the filename's slug.                                            |
| `kind`        | string   | yes      | One of the closed-vocabulary `kind` values (see below).                                        |
| `version`     | string   | yes      | SemVer (e.g., `0.1.0`). Bumped on contract change, not on implementation change.               |
| `status`      | string   | yes      | One of `draft`, `review`, `accepted`, `implemented`.                                           |
| `talks-to`    | string[] | yes      | Array of sibling slugs that this component communicates with. May be empty `[]` if standalone. |
| `grounded-by` | string[] | yes      | Array of `<server>:<short-key>` citations. Minimum 1 entry.                                    |

Unknown frontmatter keys fail the lint. Extra keys must wait for a documented schema change.

## `kind` closed vocabulary

Allowed values at v0.1.0:

| `kind`                    | What it represents                                        |
| ------------------------- | --------------------------------------------------------- |
| `lambda`                  | An AWS Lambda function.                                   |
| `ecs-service`             | An ECS service (long-running container under a service).  |
| `ecs-task`                | A standalone ECS task definition (one-shot or scheduled). |
| `fargate-service`         | A Fargate-launch-type ECS service.                        |
| `step-function`           | A Step Functions state machine.                           |
| `dynamodb-table`          | A DynamoDB table.                                         |
| `s3-bucket`               | An S3 bucket.                                             |
| `rds-instance`            | A single RDS DB instance.                                 |
| `aurora-cluster`          | An Aurora cluster (Serverless v2 or provisioned).         |
| `sqs-queue`               | An SQS queue.                                             |
| `sns-topic`               | An SNS topic.                                             |
| `eventbridge-rule`        | An EventBridge rule (with target).                        |
| `apigw-rest`              | API Gateway REST API.                                     |
| `apigw-http`              | API Gateway HTTP API.                                     |
| `cloudfront-distribution` | A CloudFront distribution.                                |
| `vpc`                     | A VPC (the network container itself).                     |
| `subnet`                  | A subnet.                                                 |
| `security-group`          | A security group.                                         |
| `iam-role`                | An IAM role.                                              |
| `kms-key`                 | A KMS key.                                                |
| `secrets-manager-secret`  | A Secrets Manager secret.                                 |

Other AWS resources are out of scope at v0.1.0 and the contract format does not yet describe them. A v0.2 PR will extend the vocabulary; until then, components that don't fit one of these kinds are not eligible for a contract — they live as informal notes in `design.md`.

## Body sections

Exactly the following seven sections, in this order, no rename, no reorder, no additions:

1. **Purpose** — one paragraph: what this component does and why it exists in the design.
2. **Interface** — three required subsections: Inputs, Outputs, Errors. Each lists schema, encoding, and channel (HTTP, event, queue, etc.).
3. **Sequence** — narrative or pseudo-sequence of how the component handles a representative request. References the `seq-component` tag in `diagrams.d2` if a sequence diagram exists.
4. **Component view (C4 L3)** — references the `c4-l3-<container>` tag in `diagrams.d2`. The diagram itself is not duplicated here; this section names the diagram tag and adds any in-prose context.
5. **Acceptance criteria** — bulleted list of measurable acceptance items (latency budget, error rate, throughput, IaC repo path, test coverage minimum). Each item is testable.
6. **Observability** — three required subsections: Metric, Log, Trace. Each lists at least one concrete signal name and source. Detail in `observability-triple.md`.
7. **Integration points** — for each slug in `talks-to`, narrate the protocol, event shape, retry semantics, idempotency strategy. Names what travels between components, not just that they communicate.

Missing a section, reordering sections, renaming a section, or adding an eighth section all fail the lint.

## Status transitions

| From          | To            | Required to pass                                                                                                |
| ------------- | ------------- | --------------------------------------------------------------------------------------------------------------- |
| `draft`       | `review`      | Frontmatter complete; all seven sections present (some may be sketch-level).                                    |
| `review`      | `accepted`    | All sections populated with substantive content; observability triple is real, not "TBD"; ≥1 grounded-by entry. |
| `accepted`    | `implemented` | Acceptance criteria reference an IaC repo path; integration points all resolve to existing sibling contracts.   |
| `implemented` | (terminal)    | n/a — further changes start a new contract `version` bump.                                                      |

A backwards transition (e.g., `accepted` → `draft`) is allowed but must be accompanied by a `version` bump and a one-line rationale in the contract body.

## Validation rules summary

For lint convenience:

1. Frontmatter has exactly the six required keys. No extras.
2. `component` matches the filename slug.
3. `kind` is in the closed vocabulary.
4. `status` is one of the four allowed values.
5. `talks-to` is an array (may be empty).
6. `grounded-by` is an array with ≥1 entry; each entry matches the citation regex.
7. Body has exactly the seven sections in canonical order, no others.
8. Observability triple's three subsections are present and each has ≥1 concrete signal.
9. Every `talks-to` slug resolves to an existing sibling contract file.
10. Integration points narrates each `talks-to` slug.
