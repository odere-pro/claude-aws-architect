---
description: AWS-touching test discipline (LocalStack/real-AWS, isolation, network)
applyTo:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/test_*.py"
  - "**/*_test.py"
inclusion: conditional
---

- Unit tests touching AWS APIs use the SDK client mocking layer (`aws-sdk-client-mock` for JS/TS, `moto` or `botocore.stub` for Python) with no network sockets opened; CI fails the test if a real AWS endpoint is reached.
- Integration tests run against LocalStack or a sandboxed AWS account; the choice is declared per test suite (file-level header comment) and the suite never silently falls back from one to the other.
- Each test owns its fixtures: tables, buckets, queues created and torn down within the same suite. Shared mutable state across suites is forbidden because it produces order-dependent failures.
- Cross-account flows (AssumeRole, cross-account S3, cross-account event bus) carry a contract-test that exercises the trust policy from both sides; trust-policy regressions cannot be caught by unit tests alone.
- Random data uses a deterministic seed declared in the suite; unseeded `Math.random`/`uuid.v4` in test bodies is forbidden because it makes failure reproduction impossible.
- Time-dependent tests freeze time via the runtime's mock-clock library; wall-clock waits in tests are forbidden because they produce flaky CI.
