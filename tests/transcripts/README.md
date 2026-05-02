# Transcript-replay fixtures

Each subdirectory under `tests/transcripts/` is one fixture that pins a frozen prompt against the tool-call trace and artefacts the plugin must produce. The runner is `tests/run-transcripts.sh`.

Per [SPEC §10](../../docs/plan/SPEC-v4.md), this harness converts every runtime claim in the spec (specifically gates 19–27 in §11.B) into a deterministic CI assertion. Without it, "the orchestrator fans out in parallel" and "every component has a contract" are wishes, not gates.

## Fixture layout

```text
tests/transcripts/
├── README.md                    # this file
├── lib/                         # shared helpers
├── vibe-shallow/                # one fixture per directory
│   ├── prompt.txt               # required — frozen user prompt
│   ├── expected-tools.jsonl     # required — one JSON line per expected tool call
│   ├── expected-artefacts.txt   # required — one path per line under .claude/specs/<feature>/
│   └── expected-merge.json      # optional — fan-out fixtures only
├── sdlc-full-depth/             # (lands PR 17+)
├── merge-conflict/              # (lands PR 20)
├── degraded-mcp/                # (lands PR 20)
├── secret-in-diff/              # (lands PR 25)
└── iteration-cap/               # (lands PR 20)
```

## File schemas

### `prompt.txt`

Plain text. The exact prompt the user issues to `/aws`. UTF-8. Trailing newline. Non-empty.

### `expected-tools.jsonl`

JSONL — one JSON object per line. Each object declares one expected tool call:

| Field           | Type   | Required | Notes                                                                                                                  |
| --------------- | ------ | :------: | ---------------------------------------------------------------------------------------------------------------------- |
| `step`          | int    |   yes    | Position in the sequence, starting at 1.                                                                               |
| `tool`          | string |   yes    | Tool identifier (`mcp__plugin_<plugin>_<server>__<tool>` for MCP tools, or `Agent`/`Read`/`Write`/etc. for built-ins). |
| `server`        | string |    no    | Short MCP server key (`kb`, `iac`, etc.). Required for MCP calls.                                                      |
| `fan_out_index` | int    |    no    | When the orchestrator emits parallel `Agent` calls, distinguishes them within the same step.                           |

An empty file means **no tool calls expected**. The runner enforces strict-superset (every expected call must appear, in order; the actual run may include extra MCP calls but never extra `Agent` calls).

### `expected-artefacts.txt`

One file path per line, relative to `.claude/specs/<feature>/`. Empty file = no artefacts. Lines starting with `#` are comments.

### `expected-merge.json`

Only present for fan-out fixtures (per [SPEC §5.5](../../docs/plan/SPEC-v4.md)). Required keys when present:

- `specialists` — array of agent slugs that must appear in the merged response.
- `open_questions` — array of expected `## Open Questions` keys (empty when no conflict).
- `priority_rules_applied` — array of {`rule`, `chosen`, `rejected`} objects when the merge contract resolved a conflict.

## Runner modes

```bash
# Default: validate fixture format only (no Claude Code execution)
tests/run-transcripts.sh

# Filter to one fixture
tests/run-transcripts.sh --fixture vibe-shallow

# Continue past failures
tests/run-transcripts.sh --keep-going

# Execute (lands in PR 18+ — currently raises NotImplemented)
tests/run-transcripts.sh --execute

# Re-record snapshots from a live run (lands in PR 18+)
tests/run-transcripts.sh --update-snapshots
```

## Snapshot-update policy

Per [SPEC §10.4](../../docs/plan/SPEC-v4.md): "Snapshot updates require explicit `--update-snapshots` and a reviewer comment." The runner refuses to overwrite expected files unless `--update-snapshots` is passed and a `SNAPSHOT_REVIEWER` env var is set with the GitHub username of the approving reviewer.

## v0.1.0 fixture set (per SPEC §10.3)

| Fixture           | Validates                                                                                  | PR  |
| ----------------- | ------------------------------------------------------------------------------------------ | :-: |
| `vibe-shallow`    | §5.6 rule 4 (verb-of-inquiry → shallow); no fan-out; no artefacts written                  |  3  |
| `sdlc-full-depth` | §5.6 rule 2 (SDLC-artefact intent → full depth); ≥2 parallel `Agent` calls; F5+F6 produced | 17  |
| `merge-conflict`  | §5.5 priority rules with planted disagreement                                              | 20  |
| `degraded-mcp`    | §3.5: simulated `kb` 5xx → `grounding-deferred` marker                                     | 20  |
| `secret-in-diff`  | §7.2 hook 3: planted AWS access key in a write blocks                                      | 25  |
| `iteration-cap`   | O4: orchestrator halts at iteration cap with `iteration-cap-reached` marker                | 20  |

## How execution will work (PR 18+)

The `--execute` mode will:

1. Spawn a clean ephemeral working tree (in a tempdir under `$TMPDIR`).
2. Symlink the plugin into the tempdir's `.claude/plugins/`.
3. Invoke `claude` (the CLI) headless with `prompt.txt` as input.
4. Parse the resulting tool-call trace from the session transcript.
5. Compare against `expected-tools.jsonl`, `expected-artefacts.txt`, and `expected-merge.json`.
6. Emit `PASS gate-19` on match; `FAIL gate-19` with a unified diff on mismatch.

This is documented now so PR 18's wiring lands against an established contract.
