---
name: aws-grounding-cache
description: |
  **WORKFLOW SKILL** — Maintain the per-feature grounding ledger:
  insert MCP citation entries, dedupe by short-key, expire by TTL class
  (pricing/quota/api-shape/region/immutable), redact secrets on write,
  and derive short-keys with collision extension.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent has just made a successful MCP call and needs to record the citation, or any time an agent needs to look up an existing citation before deciding whether to re-fetch. The discovery agent owns the write-side; every reader (orchestrator, solution-architect, implementation, security, cost) consults it before issuing a new MCP call.

Trigger conditions:

- An MCP call returned successfully and the result must be cached.
- An agent is about to issue an MCP call and wants to check whether a fresh citation already exists in the ledger.
- A short-key needs to be derived for a new query.
- A short-key collision was detected at write-time.
- An entry's TTL has elapsed and the agent is deciding whether to re-fetch or surface a stale-data marker.
- The orchestrator is flushing a `conflict_resolution` entry produced by the merge contract (the orchestrator is the writer; this skill provides the schema and the write path).

## Procedure

1. **Locate the ledger file.** It lives at `.claude/specs/<feature>/.grounding-ledger.json`, git-ignored. If the file does not exist for the current feature, create it from `assets/grounding-ledger.json.tmpl`.
2. **Derive the short-key.** Canonicalise the query (lowercase, collapse whitespace, sort URL parameters), take SHA-1, and use the first 8 hex chars. Full algorithm and collision behaviour in `references/collision-policy.md`.
3. **Check for an existing entry.** If a short-key matches and the entry is within its TTL (per `references/ttl-policy.md`), return it; do not issue a new MCP call.
4. **Redact before writing.** Run the result through the redaction patterns before persistence: AWS access keys, secret keys, session tokens, account IDs in IAM/STS/S3 context, ARNs with embedded sessions, pre-signed URL signatures, and the `aws_*_key` regex family. Full pattern catalogue, application order, and failure handling in `references/redaction-policy.md`. The unredacted result must never reach disk; redaction failure aborts the write.
5. **Insert with the canonical schema.** Each entry carries `server`, `tool`, `query`, `retrieved` (ISO-8601 UTC), `result_summary`, and `ttl-class`. Schema rules in `references/ledger-schema.md`.
6. **Dedupe.** If a write would produce a duplicate `(server, short-key)` pair, the new entry replaces the old one and `retrieved` is updated. Do not append silently — duplicates are an error in the calling agent.
7. **Expire on read.** When a reader looks up an entry, compare `retrieved` to the TTL window for the entry's `ttl-class`. If expired, surface the stale-data flag to the caller; do not return the value as if it were fresh.

## Gotchas

- **Do not commit the ledger file.** It contains MCP responses that may include account-specific details. The `.gitignore` rule lives at the repo root; the discovery agent verifies it before any write.
- **Do not skip redaction on "obviously safe" responses.** Redaction is unconditional on write. A response that "looks safe" today may carry a token tomorrow if upstream changes its payload shape.
- **Do not re-fetch an entry just because its result-summary is short.** TTL is the only re-fetch trigger. Short summaries are valid; the size of the cached value carries no signal.
- **Do not collapse `ttl-class` values.** Pricing (30d) and quotas (30d) happen to share a window today, but they are semantically distinct and may diverge. Keep them tagged separately.
- **Do not derive short-keys from raw queries without canonicalisation.** Whitespace, parameter order, and case affect SHA-1; without canonicalisation, identical queries produce different short-keys and the cache leaks.
- **Do not silently extend the short-key on every write.** Extension to 12 hex chars happens only on detected collision, only for the colliding entry, and is recorded in the entry itself so future readers know the longer key is canonical for that query.

## Boundaries

- This skill MUST NOT make MCP calls itself. Calls are issued by `aws-mcp-routing`; this skill caches the results.
- This skill MUST NOT validate the _truth_ of a cached value. Truth is the upstream MCP server's responsibility; freshness is this skill's responsibility (via TTL).
- This skill MUST NOT read the ledger from outside the current feature directory. Cross-feature reads break the per-feature isolation.
- This skill MUST NOT transmit the ledger off the local machine. The ledger is git-ignored and the plugin emits no telemetry.
- This skill MUST NOT extend a short-key to anything other than 12 hex chars. The collision-extension policy is fixed; longer extensions are an out-of-band schema change.
- This skill MUST NOT trust agent-supplied `retrieved` timestamps. The write path generates the timestamp from system time at write moment.

## Quality Checks

Before returning from a write or read operation, confirm:

- The ledger file is at the correct per-feature path and is listed in `.gitignore`.
- The short-key matches the canonical SHA-1-prefix algorithm and the collision-extension rule.
- The entry's `ttl-class` is one of `pricing`, `quota`, `api-shape`, `region`, `immutable` — no other values.
- The redaction step ran on the value before write; the on-disk entry contains no AWS access keys, secret keys, session tokens, or sensitive ARNs.
- On read, the TTL comparison is computed against current UTC, not against the writer's clock.
- Any deduplication replaced the prior entry rather than appended a sibling.
