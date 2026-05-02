# Redaction policy

Loaded on demand by the `aws-grounding-cache` skill. Defines the patterns redacted from MCP responses before they are written to the on-disk ledger, and the order in which redactions are applied.

## Why redaction is unconditional

The grounding ledger persists summaries of MCP responses to disk. Some responses may include account-specific identifiers, transient tokens, or other sensitive data. Redaction runs on every write, regardless of whether the responding tool is "expected" to return secrets — upstream payload shapes change, and an MCP server that returned safe data yesterday may return a token tomorrow.

The redaction step is applied to both the `result_summary` field and any value that would be persisted under the entry. The unredacted value never reaches disk; if redaction fails or raises, the write fails — there is no fallback that writes the raw value.

## Pattern catalogue

Redaction patterns are applied in this order. Each match is replaced with the indicated placeholder:

| Order | Name                       | Pattern (regex, case-insensitive)                                                       | Placeholder       |
| ----- | -------------------------- | --------------------------------------------------------------------------------------- | ----------------- |
| 1     | AWS access key ID          | `\bAKIA[0-9A-Z]{16}\b`                                                                  | `[REDACTED:AKID]` |
| 2     | AWS temporary access key   | `\bASIA[0-9A-Z]{16}\b`                                                                  | `[REDACTED:AKID]` |
| 3     | AWS secret access key      | `(?i)aws_secret_access_key\s*[=:]\s*[A-Za-z0-9/+=]{40}`                                 | `[REDACTED:SAK]`  |
| 4     | AWS session token          | `(?i)aws_session_token\s*[=:]\s*[A-Za-z0-9/+=]{100,}`                                   | `[REDACTED:STS]`  |
| 5     | Generic `aws_*_key` family | `(?i)aws_[a-z0-9_]*_key\s*[=:]\s*[A-Za-z0-9/+=_-]{20,}`                                 | `[REDACTED:KEY]`  |
| 6     | 12-digit AWS account ID    | `\b\d{12}\b` _when adjacent to_ `account`, `:iam:`, `:sts:`, `:s3:`, or any ARN context | `[REDACTED:ACCT]` |
| 7     | ARN with embedded session  | `arn:aws:sts::\d{12}:assumed-role/[^/\s]+/[^\s]+`                                       | `[REDACTED:ARN]`  |
| 8     | Pre-signed URL signature   | matches `X-Amz-Signature=…` or `Signature=…` followed by 40+ hex chars                  | `[REDACTED:SIG]`  |

Pattern 8 in regex form (kept out of the table because the `|` confuses Markdown columns): `(?i)(?:X-Amz-Signature|Signature)=([A-Fa-f0-9]{40,})`.

Order matters: patterns 1 and 2 strip access-key IDs before pattern 6 looks at digit runs (so an `AKIA…` containing a 12-digit substring is not partially leaked). Pattern 5 is a backstop; specific named patterns (3, 4, 7) take precedence and run first.

## Negative cases — what is NOT redacted

- **Region names** (`eu-west-1`, `us-east-2`): not sensitive, load-bearing for the cached summary.
- **Service names** (`s3`, `ec2`, `dynamodb`): not sensitive.
- **Public ARN structural prefixes** (`arn:aws:s3:::`, `arn:aws:iam::aws:`): not sensitive; the `aws:` placeholder for managed policies is intentionally public.
- **Pricing values** (`$0.023`): not sensitive; needed for cost decisions.
- **Generic 12-digit numbers** (e.g., a quota value of `1000000000000`): redacted only when adjacent to account/IAM/STS/S3 context per pattern 6. Bare 12-digit numbers in a pricing summary are not redacted.

The "adjacent to" check on pattern 6 is intentionally fuzzy. Reviewers should treat any account-ID redaction as best-effort and not rely on the cache as a sole defence against PII leakage.

## What to do when redaction matches

1. Replace the match with the placeholder string.
2. Do not log the redacted value, the position, or any partial substring. The redaction event itself is recorded as a per-entry boolean (e.g., `result_summary` differs from upstream raw); the specific value is not.
3. Continue with the write. A redacted entry is still a valid entry; the redacted summary is sufficient for the caller's grounding purpose.

## What to do when redaction fails

A "failure" means the redaction step raised, returned malformed output, or could not produce a result for any reason. In all cases:

1. Abort the write. The ledger entry is not created.
2. Surface a `grounding-deferred` marker to the caller with the reason `redaction-failed`.
3. The caller decides whether to re-issue the MCP call (which may succeed but again hit the redaction failure) or proceed with the un-cached value held in memory only for the current session.

There is no fallback that writes the raw value with a "best effort" caveat. If redaction cannot run, the value does not reach disk.

## Implementer's verification

Before declaring a write path conformant:

1. Walk the pattern catalogue with sample inputs containing each pattern; assert each is replaced with the correct placeholder.
2. Walk the negative-case list; assert each remains untouched.
3. Confirm the pattern application order: an input containing both an `AKIA…` and a bare 12-digit substring inside it must produce a single `[REDACTED:AKID]`, not partial leakage.
4. Confirm that a redaction failure aborts the write and does not partially populate the ledger.

## Versioning

The pattern catalogue is part of the skill's contract. Adding a new pattern is a non-breaking change (more is redacted). Removing or weakening a pattern is breaking and requires a documented decision; readers of older entries do not retroactively get the weaker policy applied.
