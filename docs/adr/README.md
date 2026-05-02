# Architecture Decision Records

This directory holds the v0.1.0 ADRs for `claude-aws-architect`. Each ADR captures the **rationale** behind a decision recorded declaratively in [`docs/plan/SPEC-v4.md`](../plan/SPEC-v4.md). The SPEC remains the source of truth for *what* the plugin does; the ADRs explain *why* a particular path was taken and what alternatives were rejected.

## Index

| ID  | Title                                                                                  | SPEC anchor         |
| --- | -------------------------------------------------------------------------------------- | ------------------- |
| A1  | [AWS plugin architecture](./ADR-0001-aws-plugin-architecture.md)                       | §1, §2, §5          |
| A2  | [Component contracts as deliverable](./ADR-0002-component-contracts-as-deliverable.md) | §1.1 F5, §4.2, §5.2 |
| A3  | [AWS MCP server roster](./ADR-0003-aws-mcp-server-roster.md)                           | §3.1, §3.2, §3.5    |
| A4  | [Merge contract](./ADR-0004-merge-contract.md)                                         | §5.5                |
| A5  | [Escalation heuristic](./ADR-0005-escalation-heuristic.md)                             | §5.6                |
| A6  | [License and distribution](./ADR-0006-license-and-distribution.md)                     | §15                 |
| A7  | [Supply chain and release](./ADR-0007-supply-chain-and-release.md)                     | §16, §17            |

## Conventions

- One file per decision, named `ADR-NNNN-<kebab-slug>.md` with a four-digit zero-padded ID.
- Format: **Context → Decision → Alternatives considered → Consequences → Revisit when**.
- Status field: `Accepted` for v0.1.0 baseline ADRs; future records may use `Proposed`, `Superseded by ADR-MMMM`, or `Deprecated`.
- ADRs ship in their own `docs(adr)` PR; never bundled with feature commits.
- Updates that change a decision land as a **new** ADR that supersedes the prior one — ADRs are immutable history once accepted, except for trivial typo fixes.

## Why ADRs live here and not in the SPEC

The SPEC is declarative: it tells the implementer the rule. ADRs are argumentative: they tell the next maintainer the reasoning, the alternatives that were weighed, and the conditions under which the decision should be revisited. Mixing the two would inflate the SPEC and erode the line between "the contract" and "the conversation that produced the contract".
