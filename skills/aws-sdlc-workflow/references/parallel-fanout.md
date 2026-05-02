# Parallel fan-out

Loaded on demand by the `aws-sdlc-workflow` skill. Defines how the orchestrator invokes L3 specialists in parallel, what counts as a parallel invocation, and what the per-specialist budgets are.

## The single-message rule

Full-depth fan-out is one message containing multiple `Agent` tool calls — one per specialist invoked. The Claude Code runtime issues all the calls concurrently when they appear in the same message. Sequential invocation (one `Agent` call, await, then the next) defeats the parallel design and inflates user-visible latency by 2–3×.

A correct fan-out:

```text
Orchestrator turn N:
  Agent(discovery)        ─┐
  Agent(solution-architect) ├─ all in one message; runtime parallelises
  Agent(implementation)    ─┘
```

An incorrect fan-out:

```text
Orchestrator turn N:
  Agent(discovery)
  await
  Agent(solution-architect)
  await
  Agent(implementation)
```

The incorrect version costs 3× the wall-clock time and burns the Claude Code message budget; the runtime cannot detect the intent to parallelise when calls are spread across messages.

## Specialist eligibility per phase

Not every specialist runs in every turn. The depth heuristic + active phase determines who is invoked:

| Phase     | Specialists invoked at full depth                                  |
| --------- | ------------------------------------------------------------------ |
| Discovery | discovery agent only.                                              |
| Design    | solution-architect agent only.                                     |
| Plan      | implementation agent only.                                         |
| Validate  | None (deterministic gates + rule lints; no specialist invocation). |

At v0.1.0 the L3 specialists are bundled (one specialist per phase); v0.2 splits the implementation agent into cost-engineer, security-engineer, and test-engineer. When v0.2 lands, the Plan-phase fan-out becomes truly parallel:

```text
Plan turn (v0.2):
  Agent(implementation)
  Agent(cost-engineer)
  Agent(security-engineer)
  Agent(test-engineer)
```

The single-message rule remains; the parallelism just becomes visible.

## MCP-call budget per specialist

Each specialist has a per-invocation MCP-call budget enforced by `aws-mcp-routing`:

| Specialist         | Budget |
| ------------------ | ------ |
| discovery          | 8      |
| solution-architect | 12     |
| implementation     | 16     |

When a specialist exhausts its budget, it returns control to the orchestrator with a `budget-exhausted` marker. The orchestrator surfaces the marker under `## Degraded signals` and proceeds with the partial output. Re-invoking the same specialist in the same turn to "finish" the work is forbidden — it doubles the budget and hides the design defect that caused the exhaustion.

## Specialist-to-MCP-server map

The orchestrator does not pick which MCP server a specialist uses; that is a property of the specialist's declaration. For reference:

| Specialist         | MCP servers it may consult  |
| ------------------ | --------------------------- |
| discovery          | `kb` (aws-knowledge).       |
| solution-architect | `kb`, `iac`.                |
| implementation     | `iac`, `cost`, `iam`, `cw`. |

Routing inside a specialist is delegated to `aws-mcp-routing`.

## When sequencing IS legitimate

A sequenced (non-parallel) edge between two specialists is legitimate only when the second specialist _cannot start_ without an output from the first. Examples:

- The implementation agent needs `design.md` to fill in contract IaC sections — but `design.md` was written in a prior turn, not produced by a same-turn solution-architect invocation. So no in-turn sequencing edge.
- A re-invocation triggered by a degraded marker — but this is forbidden at v0.1.0 (no re-invocation in the same turn).

In practice at v0.1.0, every full-depth turn invokes exactly one specialist (since one specialist per phase). The single-message rule still applies trivially. The rule becomes load-bearing once v0.2 splits implementation into multiple specialists.

## Result handling

After all parallel specialists return:

1. The orchestrator receives one tool result per specialist, in arrival order.
2. The merge contract (in `merge-rules.md`) reduces the parallel results into the single user-facing response.
3. Any specialist that timed out or exhausted budget surfaces as a degraded marker; their partial output is merged with their marker attached.

There is no early-return: the orchestrator waits for all specialists to complete (or fail) before merging. Returning early with partial parallel results would hide the rest and produce an inconsistent merged answer.
