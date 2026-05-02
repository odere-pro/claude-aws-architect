# Collision policy

Loaded on demand by the `aws-grounding-cache` skill. Defines short-key derivation and the collision-extension behaviour.

## Short-key derivation

For each MCP query the cache produces a short-key:

1. **Canonicalise the query.**
   - Lowercase the entire string.
   - Collapse runs of whitespace (spaces, tabs, newlines) to a single space.
   - Trim leading and trailing whitespace.
   - For URL-form queries, sort query parameters alphabetically by name.
   - For keyword queries (free-text terms passed to a search/discovery tool), sort tokens alphabetically. **Caveat**: this means `"ec2 instance"` and `"instance ec2"` produce the same short-key. The cache treats keyword-token order as semantically irrelevant. Tools whose semantics _do_ depend on argument order (e.g., positional API parameters) MUST be invoked via URL-form so the parameter-name preserves the binding; do not invoke order-sensitive tools through the keyword path.
   - Drop trailing punctuation that does not affect meaning (`?`, `!`, `.`).
2. **Hash.** Compute `SHA-1(canonical_query)`.
3. **Truncate.** Take the first 8 hex characters of the hex-encoded hash. This is the base short-key.

Short-key example (real SHA-1 values; verify with `printf '%s' "<canonical>" | shasum | cut -c1-8`):

| Raw query                     | Canonical form              | SHA-1 prefix |
| ----------------------------- | --------------------------- | ------------ |
| "Lambda Concurrency Limits"   | `concurrency lambda limits` | `ad284d1b`   |
| "concurrency lambda LIMITS"   | `concurrency lambda limits` | `ad284d1b`   |
| "limits, concurrency, lambda" | `concurrency lambda limits` | `ad284d1b`   |

All three raw queries canonicalise to the same string (lowercase, sorted tokens, punctuation dropped) and produce the same short-key, ensuring cache hits for semantically equivalent keyword queries.

## Stop words

The canonicaliser does **not** strip stop words. "in", "and", "the" stay. Reasoning: stripping stop words across query types is fragile (some are load-bearing, e.g., `iam:role/admin/in/foo`), and the SHA-1-of-canonical approach is robust enough without it. Two queries that differ only in stop-word presence produce different short-keys; that is acceptable cache miss, not a defect.

## Collision detection

A collision occurs when a write-time short-key already exists in `entries` for the **same server** but a **different `query` field**. (Same query → not a collision; that is a dedupe and the existing entry is replaced per the dedupe rule.)

When detected:

1. Recompute the short-key for the _new_ incoming entry as the first **12** hex chars of the same SHA-1.
2. Insert the new entry under `<server>:<12-hex-key>`.
3. Set `short_key_ext: true` on the new entry.
4. Leave the existing 8-hex entry untouched. (Do not retroactively extend the existing entry; readers who hold the original citation must remain valid.)

The space of 8-hex SHA-1 prefixes is 16^8 ≈ 4.3 billion; collisions in a per-feature ledger are expected to be rare, but the policy must exist before the first collision is observed in the wild.

## Worked example

State:

```json
"entries": {
  "kb:9c1a2f30": { "server": "kb", "query": "s3 bucket naming rules", ... }
}
```

A new write arrives for `query = "ec2 instance metadata service v2"` whose SHA-1 prefix is also `9c1a2f30`. The cache:

1. Detects the collision (same server `kb`, same prefix `9c1a2f30`, different query).
2. Computes the 12-hex prefix of the new SHA-1, e.g., `9c1a2f30b487`.
3. Writes the new entry under `kb:9c1a2f30b487` with `short_key_ext: true`.

Resulting state:

```json
"entries": {
  "kb:9c1a2f30":      { "server": "kb", "query": "s3 bucket naming rules", ... },
  "kb:9c1a2f30b487":  { "server": "kb", "query": "ec2 instance metadata service v2", "short_key_ext": true, ... }
}
```

Future readers who compute the 8-hex short-key for the EC2 query will not find a match; they must compute the 12-hex prefix as a fallback. The lookup algorithm:

1. Compute 8-hex short-key.
2. Check `entries[<server>:<8-hex>]`. If present **and** the `query` field equals the canonicalised lookup query, hit.
3. Otherwise compute the 12-hex short-key.
4. Check `entries[<server>:<12-hex>]`. If present **and** `short_key_ext: true` **and** the `query` field equals the canonicalised lookup query, hit. The query-field equality check is mandatory at every lookup step; matching on the key alone is never sufficient.
5. Otherwise miss.

## Why not 12 hex unconditionally

8-hex keys are short enough to read in citations like `kb:9c1a2f30` without overwhelming the spec body. Extending only on collision keeps the common case readable while preserving uniqueness when needed. Unconditional 12-hex would visually clutter every citation for a problem that does not yet exist.

## Why not extend further on a 12-hex collision

A 12-hex collision in a per-feature ledger would imply ≥ 2^24 entries — vastly beyond any realistic feature scope. If it ever happens, the ledger is being misused (e.g., feature scope too broad, multiple features merged) and the right fix is to split, not to keep extending. If observed, the write fails loudly rather than silently extending to 16+ hex.
