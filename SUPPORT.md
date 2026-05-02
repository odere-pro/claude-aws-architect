# Support

`claude-aws-architect` is a community plugin maintained best-effort by the project owner. This document describes what kind of support to expect and where to get it.

## Posture

- Support is **best-effort, community-driven, no SLA**.
- The supported version is the latest tagged release on `main`. There are no backports unless the active version is v1.0+.
- Contributions are welcome; see [docs/plan/PR-CONVENTIONS.md](./docs/plan/PR-CONVENTIONS.md).

## Where to get help

| What you need                | Where to go                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------- |
| Bug reports                  | [GitHub Issues](https://github.com/odere-pro/claude-aws-architect/issues) — use the bug template (lands PR 28b) |
| Feature requests             | GitHub Issues — use the feature-request template (lands PR 28b)                 |
| How-to / discussion          | [GitHub Discussions](https://github.com/odere-pro/claude-aws-architect/discussions) |
| Security vulnerability       | See [SECURITY.md](./SECURITY.md) — **not** a public issue                       |

## What gets fixed

| Severity | Examples                                                          | Triage                                  |
| -------- | ----------------------------------------------------------------- | --------------------------------------- |
| Critical | Plugin breaks Claude Code, exposes secrets, corrupts user data    | Hotfix branch, prioritised over all else |
| High     | A gate in §11 fails for a real-world repo; degraded mode breaks   | Next release                            |
| Medium   | Polish, ergonomics, error-message clarity                         | When time permits                       |
| Low      | Style, typos, minor docs                                          | Welcomes PRs                            |

Feature requests are triaged into `v0.2`, `v1.0`, or `wontfix` labels. `wontfix` always carries a one-line rationale.

## What does not get fixed here

Issues with upstream MCP servers, Claude Code itself, or the AWS APIs — see the **Out of scope** section in [SECURITY.md](./SECURITY.md) for the right escalation path.

## Versioning and release cadence

Per [SPEC §17](./docs/plan/SPEC-v4.md):

- SemVer — pre-1.0 minors may break public spec interfaces (CHANGELOG calls out every break).
- Releases are tagged on `main` after the release dogfood gate (§11.E gate 34) passes.
- Each tagged release is published as a GitHub Release with a `tar.gz` and SHA-256 checksum.

## Reporting and feedback

If something is genuinely broken, file an issue. If something is just confusing, file a Discussion — confusing UX is a real bug, but discussion-format helps converge on the right fix before any code lands.
