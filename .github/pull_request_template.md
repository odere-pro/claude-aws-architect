<!--
  Title format: <type>(<scope>): <subject>
  Branch format: <type>/aws-plugin-<NN>-<slug>
  See docs/plan/PR-CONVENTIONS.md for the authoritative rules.
-->

## What

One paragraph: what this PR adds, removes, or changes.

## Why

Reference the spec section(s) that authorise this work (e.g. "Per §12.A.1 and §3.1").

## Gates exercised

List the §11 gate IDs this PR makes pass or extends. Use the same numbering as `docs/plan/PR-PLAN.md`.

- Gate N: ...

## Depends on

PR numbers from `docs/plan/PR-PLAN.md` that must be merged first. Link them.

- #N (merged)

## Test plan

- [ ] CI green (which workflows run for this PR?)
- [ ] Manual verification: ...
- [ ] Local replay of relevant transcript fixtures (if applicable)

## Out of scope

Anything a reviewer might expect to see but isn't here, with a one-line rationale (e.g. "ADR for this decision lands in PR #32").

## Merge strategy

<!-- Pick one. See docs/plan/PR-CONVENTIONS.md §"Merge strategy" — default is merge-commit for PRs that ship executable artefacts. -->

- [ ] Merge-commit (preserves the build sequence inside the PR)
- [ ] Squash-merge (planning, ADRs, docs-only, hotfixes)

## Pre-merge checklist

- [ ] All CI workflows green on the PR branch.
- [ ] CHANGELOG entry added under `## Unreleased` (per §N9).
- [ ] `Depends on` items above are all merged.
- [ ] No unresolved review comments.
