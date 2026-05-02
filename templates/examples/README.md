# Examples

Captured smoke artefacts from the canonical `/aws` runs. Each
subdirectory is a complete, executable reference: the exact set of
files the orchestrator + L3 specialists produce when run against a
specific seed prompt.

These directories are **read-only references**. Do not hand-edit them
to tune wording — re-capture from the fixture instead so the example
stays a faithful trace of the live workflow.

## What lives here

- **`order-processing-pipeline/`** — captured from the
  `tests/transcripts/sdlc-full-depth/` fixture, which exercises §5.6
  rule 2 (SDLC-artefact intent → full depth) and ≥2 parallel `Agent`
  calls. Holds the full F5 + F6 artefact set: `requirements.md`,
  `design.md`, `tasks.md`, `diagrams.d2`, four contracts under
  `contracts/`, and the `.grounding-ledger.json` (committed for
  illustration; in a consumer project this file is git-ignored per
  §H4).

## How an example is captured

1. Pick a fixture under `tests/transcripts/<name>/` that exercises the
   intended depth and fan-out shape.
2. Run `/aws` against the fixture's `prompt.txt`.
3. Verify the produced `.claude/specs/<feature>/` tree against the
   fixture's `expected-artefacts.txt` and `expected-merge.json`.
4. Run the deterministic gates in §11.A and the runtime gates in §11.B
   against the produced tree; every gate must PASS.
5. Copy the verified tree under `templates/examples/<feature>/`.

## What each example demonstrates

The example is the canonical executable reference §11 gates point at
per §H5: a real, validated artefact set that the spec validator
accepts at status `review` without raising any TODO-token violations
or grounded-by gaps. New consumer projects can read these directories
to understand the expected shape and depth of a populated spec
before running the workflow themselves.

## Verification

`tests/gates/run-all.sh` and `tests/run-transcripts.sh` cover this
directory in their normal scans. The example artefacts are real
Markdown (no `.tmpl` suffix) so they are checked by markdownlint and
prettier in gate 14.
