---
description: AWS SDK client construction, retries, pagination, region resolution
applyTo:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.py"
inclusion: conditional
---

- AWS SDK clients are constructed once per process at module scope; client instantiation never happens inside a Lambda handler, request loop, or other hot path.
- Retry behaviour is configured explicitly: `maxAttempts` set, exponential back-off enabled, and idempotent operations are the only ones retried — non-idempotent calls (`Put*`, `Send*`) carry an idempotency token and are never blindly retried.
- All `List*` and `Describe*` calls use the SDK's pagination iterator; manual `NextToken`/`Marker` loops are forbidden because they leak the page state on early exit.
- Credentials come from the default provider chain (instance profile, IRSA, container role); no module instantiates a client with hardcoded `accessKeyId`/`secretAccessKey` outside of a vetted local-development bootstrap.
- Region is resolved from the SDK's default region resolver or from a single named env var (`AWS_REGION`); inline string literals like `"us-east-1"` are forbidden in production code paths.
- Async errors are narrowed to typed error shapes (`ServiceException`, `ThrottlingException`); blanket `catch (e)` blocks must rethrow or surface the error type.
