# PR conventions — `claude-aws-architect`

Conventions for branches, commits, PRs, and merges. Applies to every PR in [PR-PLAN.md](./PR-PLAN.md).

## Branch naming

Format: `<type>/aws-plugin-<NN>-<slug>`

- `<type>` — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `perf`. Matches the leading commit type.
- `<NN>` — zero-padded two-digit PR number from `PR-PLAN.md` (e.g. `01`, `09`, `28a`).
- `<slug>` — kebab-case, ≤4 words, summarising scope. Matches the slug in `PR-PLAN.md`.

Examples:

- `feat/aws-plugin-01-scaffold`
- `feat/aws-plugin-19-agent-solution-architect`
- `chore/aws-plugin-31-release-dogfood`
- `docs/aws-plugin-32-adrs`

The single exception is PR 0 (this planning import), which lives on the pre-existing `feat/aws-mcp-plugin` branch.

## Commit message format

Conventional Commits with no attribution footer (per global git-workflow rule).

```text
<type>(<scope>): <subject>

<body — optional, wrap at 72 cols, explains *why* not *what*>
```

- `<type>` — same vocabulary as branch type prefix.
- `<scope>` — one of: `plugin`, `mcp`, `agent`, `skill`, `rule`, `power`, `hook`, `script`, `ci`, `docs`, `adr`, `plan`, `deps`, `repo`. Choose the narrowest applicable scope.
- `<subject>` — imperative mood, lowercase, no trailing period, ≤72 chars.
- Body — optional but expected for any non-trivial change. Cite the spec section that authorises the change (e.g. "per §5.5 merge contract").

Examples:

```text
feat(plugin): scaffold manifest and 6-server .mcp.json

Lands the v0.1.0 .mcp.json with all 6 servers from §3.1, each carrying
a pinned version (per §16.2) and timeoutMs (per O2). README, SPEC,
CHANGELOG, LICENSE skeletons included so subsequent PRs can extend
them without restructuring.
```

```text
feat(skill): add aws-mcp-routing

Implements §13 substrate item; references degraded-modes table from §3.5.
Sibling trigger-keywords.txt added for §11.A gate 16.
```

```text
docs(adr): record A4 merge-contract rationale

Captures the priority order in §5.5 and the conflict-surfacing format,
including why grounded-by citations beat un-grounded claims.
```

## PR title

Same format as commit subject without the body: `<type>(<scope>): <subject>`. PR titles match the title of the squashed commit (when squash-merged) or the merge-commit subject (when merge-commit'd).

## PR body template

```markdown
## What

One paragraph: what this PR adds, removes, or changes.

## Why

Reference the spec section(s) that authorise this work (e.g. "Per §12.A.1 and §3.1").

## Gates exercised

List the §11 gate IDs this PR makes pass or extends. Use the same numbering as `PR-PLAN.md`.

- Gate 2: ...
- Gate 12: ...

## Depends on

PR numbers from `PR-PLAN.md` that must be merged first. Link them.

- #N (merged)

## Test plan

- [ ] CI green (which workflows run for this PR?)
- [ ] Manual verification: ...
- [ ] Local replay of relevant transcript fixtures (if applicable)

## Out of scope

Anything a reviewer might expect to see but isn't here, with a one-line rationale (e.g. "ADR for this decision lands in PR #32").
```

The full template lives in `.github/pull_request_template.md` once PR 28b ships.

## Merge strategy

Two strategies, chosen by PR type:

| PR type                                      | Strategy                     | Rationale                                                                                                                           |
| -------------------------------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Planning, ADR, docs-only                     | **Squash-merge**             | One commit per logical unit on `main`; intermediate edit churn is noise.                                                            |
| Feature PRs (skills, agents, hooks, scripts) | **Merge-commit (no squash)** | Preserves the build sequence inside the PR — useful for `git bisect` and for understanding how a multi-step change was constructed. |
| Hotfixes                                     | **Squash-merge**             | Single fix → single commit on `main`.                                                                                               |

Default is **merge-commit** for any PR that lists more than one commit-within-PR in `PR-PLAN.md` or that ships executable artefacts (skills, agents, scripts, hooks). Default is **squash-merge** for everything else.

The PR author selects the strategy at merge time; if unsure, the table above is authoritative.

## Required checks before merge

- All CI workflows green on the PR branch.
- At least one approving review from the project owner.
- No unresolved review comments.
- PR description's `Depends on` items all merged.
- CHANGELOG entry added under the `## Unreleased` section (one bullet per PR per §N9).

## Branch lifecycle

- Branch from `main` at the latest merged commit.
- Open PR against `main` as soon as the first commit lands on the branch (draft is fine).
- Rebase (not merge) `main` into the branch when needed; force-push is allowed on feature branches.
- Delete the branch immediately on merge (GitHub auto-delete enabled).
- Never reuse a branch name after merge.

## Reviewer

The project owner (`@odere-pro`) is the sole reviewer at v0.1.0. No `CODEOWNERS` file is required while the team is one person.
