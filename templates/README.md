# Templates

Consumer-facing scaffolding for `claude-aws-architect`. The install script
copies (or symlinks) the contents of this directory into a consumer
project's `.claude/` tree on first run; the orchestrator and specialist
agents then write generated artefacts into the per-feature subdirectories.

## Layout

```text
templates/
├── .claude/
│   ├── claude-aws-architect.local.md.example   # local consumer settings
│   └── specs/
│       └── __feature__/                        # placeholder for a feature slug
│           ├── requirements.md.tmpl
│           ├── design.md.tmpl
│           ├── tasks.md.tmpl
│           ├── diagrams.d2.tmpl
│           └── contracts/
│               └── __slug__.md.tmpl            # one per component named in design.md
└── examples/                                   # captured smoke artefacts (lands in a follow-up PR)
```

## Placeholder convention

- `__feature__` — replace with a kebab-case feature slug (e.g., a single
  feature scope per directory).
- `__slug__` — replace with a kebab-case component slug; the slug must
  match the contract's `component:` frontmatter key.
- The `.tmpl` suffix is stripped at scaffold time. Drop the suffix when
  copying the template into the live spec directory.

## TODO tokens

Every template uses literal `TODO` tokens for fields that the agent (or the
human author) must fill in. The validator command refuses to advance a
spec past `status: draft` while any `TODO` token remains in a required
field.

## What lives where

- **`requirements.md.tmpl`** — user-facing goals, acceptance criteria with
  `grounded-by` citations, non-functional requirements, constraints.
- **`design.md.tmpl`** — architecture overview with layered-diagram links,
  per-component summary, design choices, per-pillar Well-Architected
  review block, surfaced open questions and degraded signals.
- **`tasks.md.tmpl`** — implementation backlog. Each task traces to one or
  more acceptance criteria and to the relevant component contracts.
- **`contracts/__slug__.md.tmpl`** — per-component contract with
  Purpose / Interface / Sequence / Component view / Acceptance / Observability
  triple / Integration points.
- **`diagrams.d2.tmpl`** — single D2 file carrying every required layer
  tag (`c4-l1`, `c4-l2`, one `c4-l3-<container>` per L2 container,
  `seq-system`, `seq-component`, `seq-error`).
- **`claude-aws-architect.local.md.example`** — overrides for AWS region,
  cost ceiling, IAM posture, observability defaults, and authoring
  defaults; copy to `claude-aws-architect.local.md` and edit per project.

## What does **not** live here

- Skill-side templates (consumed by skills at runtime) live under
  `skills/<skill-name>/assets/`. Those are not user-facing and are not
  copied by the install script.
- The grounding ledger schema (`grounding-ledger.json.tmpl`) is owned by
  the `aws-grounding-cache` skill and seeded automatically on first run;
  it is not a consumer-edited artefact.

## Verification

`tests/gates/run-all.sh` invokes the deterministic gates that scan this
tree alongside the rest of the plugin. The `.tmpl` extension keeps these
files outside the markdownlint and prettier matchers (which only inspect
`*.md`); the embedded YAML frontmatter is still well-formed and the file
contents are still valid Markdown for human readability.
