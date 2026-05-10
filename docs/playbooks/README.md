# Recipe playbooks — production-ready scenarios

One playbook per Recipe shipped by `claude-aws-architect`. Each playbook walks through real scenarios at three depth levels, modelled on the AWS re:Invent session-numbering convention:

| Level   | Audience                               | Depth                                                                                                                                   |
| ------- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **200** | Practitioners new to the topic         | Foundational — single service, narrow scope, one MCP server, one or two artefacts.                                                      |
| **300** | Mid-level architects and operators     | Intermediate — multiple services, cross-skill workflow, full WAF pillar review on the path.                                             |
| **500** | Expert / staff engineers, SREs, FinOps | Expert — multi-account, regulatory or scale constraints, contradictions to resolve, multi-pillar trade-offs surfaced as Open Questions. |

Each scenario includes:

1. **Persona** — who runs it.
2. **Trigger** — the problem or question that kicks it off.
3. **Invocation** — the exact slash command(s).
4. **What happens** — which agent, which MCP servers, which skills, which artefacts.
5. **Why this is production-ready** — the gate, contract, or guarantee that backs the run.

---

## Index

| Recipe                                                                                         | Focus                                                                  | Playbook                                                         |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [`claude-aws-architect-kb`](../../recipes/claude-aws-architect-kb.recipe.json)                 | Read-only lookup, CLI reference, SOPs, onboarding, next-step recs      | [kb-recipe-playbook.md](./kb-recipe-playbook.md)                 |
| [`claude-aws-architect-cdk`](../../recipes/claude-aws-architect-cdk.recipe.json)               | CDK authoring + reliability + ops + cost ROM                           | [cdk-recipe-playbook.md](./cdk-recipe-playbook.md)               |
| [`claude-aws-architect-cost`](../../recipes/claude-aws-architect-cost.recipe.json)             | Pricing-model review, right-sizing, storage tiers, tagging             | [cost-recipe-playbook.md](./cost-recipe-playbook.md)             |
| [`claude-aws-architect-security`](../../recipes/claude-aws-architect-security.recipe.json)     | WAF security pillar, IAM least-privilege, encryption, identity edge    | [security-recipe-playbook.md](./security-recipe-playbook.md)     |
| [`claude-aws-architect-bedrock-ai`](../../recipes/claude-aws-architect-bedrock-ai.recipe.json) | Amazon Bedrock + AWS AI: FMs, RAG / KBs, Agents, Guardrails, licensing | [bedrock-ai-recipe-playbook.md](./bedrock-ai-recipe-playbook.md) |

---

## How to read a scenario

A 200 scenario is meant to be runnable by a developer who has the plugin installed and a working AWS profile. A 300 scenario assumes the user has already produced a `requirements.md` for a feature and is ready to design or implement. A 500 scenario assumes a multi-account, scale-constrained, or regulated environment where the merge contract's conflict resolution (security → facts → cost → convergence → recency) and the `Open Questions` section actively shape the output.

Every scenario in every playbook is grounded by the same gates that protect the rest of the plugin:

- **Gate 6** validates the Recipe JSON schema.
- **Gates 8, 9, 10** validate rule, agent, and skill contracts.
- **Gates 16, 17** enforce skill description quality and the 500-line SKILL.md budget.
- **Gates 30–33** prove install / uninstall round-trip safety.

That is the difference between a demo and a production-ready run: the slash commands in these playbooks invoke artefacts whose shapes and side-effects are checked on every CI run.
