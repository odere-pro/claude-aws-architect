# PR execution roadmap — `claude-aws-architect` v0.1.0

This document maps the §12 execution sequence in [SPEC-v4.md](./SPEC-v4.md) to concrete pull requests. Each row is one PR. PRs land in the order shown unless the **Depends on** column is empty (in which case the PR can land in parallel with anything else whose dependencies are already merged).

Branch naming, commit format, merge strategy, and PR template are defined in [PR-CONVENTIONS.md](./PR-CONVENTIONS.md).

## Legend

- **#** — PR sequence number (also used in branch name `feat/aws-plugin-NN-slug`).
- **§ ref** — section in `SPEC-v4.md` that authorises the work.
- **Scope** — one-line summary; full scope lives in the linked spec section.
- **Gates** — `§11` gate IDs the PR must make pass (or extend) before merge.
- **Depends on** — PR numbers that must be merged first. `—` means no PR dependency.
- **Parallel-safe** — `Y` if it can be opened concurrently with other parallel-safe PRs at the same dependency level.

## PR table

| #   | Branch                                                | § ref      | Scope                                                                                                                          | Gates                  | Depends on         | Parallel-safe           |
| --- | ----------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------- | ------------------ | ----------------------- |
| 0   | `feat/aws-mcp-plugin` (planning import)               | —          | Import full v4 spec; add this roadmap and conventions doc                                                                      | —                      | —                  | N                       |
| 1   | `feat/aws-plugin-01-scaffold`                         | 12.A.1     | Plugin manifest, `.mcp.json` (6 servers, pinned, with timeouts), README, SPEC, CHANGELOG, LICENSE, SECURITY, SUPPORT skeletons | 2, 12, 15              | 0                  | N                       |
| 2   | `feat/aws-plugin-02-deterministic-gates`              | 12.A.2     | CI workflow running gates 1–18 (lint, schema, frontmatter, trademark, description, line, tool-name budgets)                    | 1, 3–11, 13, 14, 16–18 | 1                  | N                       |
| 3   | `feat/aws-plugin-03-transcript-harness-skeleton`      | 12.A.3     | `tests/run-transcripts.sh`, fixture format, first fixture (`vibe-shallow`)                                                     | 19 (skeleton only)     | 2                  | N                       |
| 4   | `feat/aws-plugin-04-skill-mcp-routing`                | 12.B.4     | Workflow skill: `aws-mcp-routing`                                                                                              | 10, 16, 17             | 2                  | Y                       |
| 5   | `feat/aws-plugin-05-skill-spec-grounding`             | 12.B.5     | Workflow skill: `aws-spec-grounding`                                                                                           | 10, 16, 17             | 2                  | Y                       |
| 6   | `feat/aws-plugin-06-skill-grounding-cache`            | 12.B.6     | Workflow skill: `aws-grounding-cache`                                                                                          | 10, 16, 17             | 2                  | Y                       |
| 7   | `feat/aws-plugin-07-skill-component-contract`         | 12.B.7     | Workflow skill: `aws-component-contract`                                                                                       | 10, 16, 17             | 2                  | Y                       |
| 8   | `feat/aws-plugin-08-skill-layered-diagram`            | 12.B.8     | Workflow skill: `aws-layered-diagram`                                                                                          | 10, 16, 17             | 2                  | Y                       |
| 9   | `feat/aws-plugin-09-skill-sdlc-workflow`              | 12.B.9     | Workflow skill: `aws-sdlc-workflow`                                                                                            | 10, 16, 17             | 2                  | Y                       |
| 10  | `feat/aws-plugin-10-skill-waf-operational-excellence` | 12.B-2.10  | Pillar skill: `aws-waf-operational-excellence-skill`                                                                           | 10, 16, 17             | 2                  | Y                       |
| 11  | `feat/aws-plugin-11-skill-waf-security`               | 12.B-2.11  | Pillar skill: `aws-waf-security-skill`                                                                                         | 10, 16, 17             | 2                  | Y                       |
| 12  | `feat/aws-plugin-12-skill-waf-reliability`            | 12.B-2.12  | Pillar skill: `aws-waf-reliability-skill`                                                                                      | 10, 16, 17             | 2                  | Y                       |
| 13  | `feat/aws-plugin-13-skill-waf-performance-efficiency` | 12.B-2.13  | Pillar skill: `aws-waf-performance-efficiency-skill`                                                                           | 10, 16, 17             | 2                  | Y                       |
| 14  | `feat/aws-plugin-14-skill-waf-cost-optimization`      | 12.B-2.14  | Pillar skill: `aws-waf-cost-optimization-skill`                                                                                | 10, 16, 17             | 2                  | Y                       |
| 15  | `feat/aws-plugin-15-skill-waf-sustainability`         | 12.B-2.15  | Pillar skill: `aws-waf-sustainability-skill`                                                                                   | 10, 16, 17             | 2                  | Y                       |
| 16  | `feat/aws-plugin-16-agent-orchestrator`               | 12.C.16    | L4 orchestrator agent (scaffold only — no fan-out yet)                                                                         | 9                      | 4–9                | N                       |
| 17  | `feat/aws-plugin-17-agent-discovery`                  | 12.C.17    | L3 discovery agent + transcript fixture                                                                                        | 9, 19                  | 16                 | N                       |
| 18  | `feat/aws-plugin-18-orchestrator-discovery-wiring`    | 12.C.18    | Wire orchestrator → discovery; first end-to-end fixture passes                                                                 | 19                     | 17                 | N                       |
| 19  | `feat/aws-plugin-19-agent-solution-architect`         | 12.C.19    | L3 solution-architect + parallel fan-out (N=2) + merge contract from §5.5                                                      | 9, 19, 20, 21, 25      | 18, 10–15          | N                       |
| 20  | `feat/aws-plugin-20-fixtures-merge-degraded-iter`     | 12.C.20    | Add `merge-conflict`, `degraded-mcp`, `iteration-cap` fixtures; pass runtime gates 19–27                                       | 19–27                  | 19                 | N                       |
| 21  | `feat/aws-plugin-21-agent-implementation`             | 12.C.21    | L3 implementation agent; fan-out at N=3                                                                                        | 9, 19–27               | 20, 11, 12, 14, 10 | N                       |
| 22  | `feat/aws-plugin-22-rules`                            | 12.D.22    | 9 file-scoped instruction rules under `rules/`                                                                                 | 8                      | 2                  | Y                       |
| 23  | `feat/aws-plugin-23-commands`                         | 12.E.23    | 3 commands: `/aws`, `/aws-spec`, `/aws-doctor`                                                                                 | 9                      | 21                 | N                       |
| 24  | `feat/aws-plugin-24-recipes`                          | 12.F.24    | 3 Recipes: `cdk`, `cost`, `security`                                                                                           | 6                      | 21, 22             | Y                       |
| 25  | `feat/aws-plugin-25-hooks-core`                       | 12.F.25    | Hooks registry, dispatcher, `secret-scanner`, `aws-api-write-guard`                                                            | 7, 11                  | 2                  | Y                       |
| 26  | `feat/aws-plugin-26-hooks-secondary`                  | 12.F.26    | 4 secondary hooks: `cdk-write`, `iam-write`, `bedrock-prompt-write`, `test-coverage`                                           | 7, 11                  | 25                 | Y                       |
| 27  | `feat/aws-plugin-27-scripts`                          | 12.F.27    | `init.sh`, `doctor.sh`, `install.sh`, `uninstall.sh`; install-safety gates 30–33                                               | 1, 4, 13, 30–33        | 25                 | Y                       |
| 28  | `feat/aws-plugin-28-ci-matrix`                        | 12.F.28    | CI matrix on ubuntu-latest + macos-latest                                                                                      | 28, 29                 | 27                 | N                       |
| 28a | `feat/aws-plugin-28a-security-supplychain`            | 12.F-2.28a | SECURITY.md, threat-model.md, Dependabot for Actions, MCP version-skew workflow                                                | 12 (extended)          | 1                  | Y                       |
| 28b | `feat/aws-plugin-28b-issue-pr-templates`              | 12.F-2.28b | SUPPORT.md, GitHub issue templates, PR template                                                                                | —                      | 1                  | Y                       |
| 29  | `feat/aws-plugin-29-templates`                        | 12.G.29    | Spec, contract, diagram templates under `templates/`                                                                           | 8, 9, 10               | 21                 | N                       |
| 30  | `chore/aws-plugin-30-self-dogfood-example`            | 12.G.30    | Capture canonical example artefact from `sdlc-full-depth` fixture                                                              | 19–24                  | 28, 29             | N                       |
| 31  | `chore/aws-plugin-31-release-dogfood`                 | 12.G.31    | Run `/aws` against plugin's own design intent prompt; produce `.claude/specs/claude-aws-architect/` meta-spec                  | 34 (release gate)      | 30                 | N                       |
| 32  | `docs/aws-plugin-32-adrs`                             | 12.H.32    | ADRs A1–A7 in a single PR                                                                                                      | —                      | —                  | Y (any time after PR 1) |

## Total: 33 PRs (0 + 32)

The lower bound is 33 because every numbered §12 item is its own PR per the §12 declared "≤500 net lines" sizing rule. PRs may be split further at author discretion if a single item starts breaching that line budget; in that case the new PR is suffixed `-a`, `-b`, etc., and inherits the same dependency edges.

## Critical path

The longest dependency chain: 0 → 1 → 2 → 3 → (4–9 in parallel) → 16 → 17 → 18 → (10–15 in parallel) → 19 → 20 → 21 → 23 → 29 → 30 → 31. Roughly 14 sequential PR-merges along the critical path; everything else (rules, recipes, hooks, scripts, security infra, ADRs) hangs off branches that can ship in parallel.

## Release gate

PR 31 (release dogfood) is the v0.1.0 tag blocker per §11.E gate 34. The plugin must successfully design itself before tag.

## Parallel-batch suggestions

After PR 2 merges, **batch A** can open simultaneously: PRs 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 22, 25, 28a, 28b, 32. That's 17 parallel branches. Author can choose to open them all and merge as each is reviewed, or land them in smaller waves to keep CI signal manageable.

After PR 21 merges, **batch B** can open: PRs 24, 26, 27, 29.

## Notes

- PR 0 (this PR) lives on the existing `feat/aws-mcp-plugin` branch by historical accident; subsequent PRs follow the `feat/aws-plugin-NN-slug` naming convention from PR 1 onward.
- ADRs (PR 32) are intentionally kept in a single PR — they are decision records, not feature work, and benefit from being reviewed together.
- The release dogfood PR (PR 31) is `chore/` not `feat/` because it produces no source code, only generated artefacts.
