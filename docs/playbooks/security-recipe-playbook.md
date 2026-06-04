# `claude-aws-architect-security` — playbook

Security-only review recipe. Bundles `sec`, `iam`, `kb` MCP servers, the `aws-waf-security-skill`, the routing / grounding / cache skills, both default PreToolUse hooks (`aws-secret-scanner`, `aws-api-write-guard`), and the `/aws`, `/aws-spec`, `/aws-doctor` commands. Deliberately excludes `iac`, `cost`, and `cw` to keep the surface focused on identity, encryption, network perimeter, and findings triage.

---

## AWS-200 — review a single IAM policy before it ships

**Persona:** A backend engineer with a draft IAM policy attached to a Lambda execution role, about to open a PR.

**Trigger:** "I think this policy is least-privilege, but I want a second pair of eyes."

**Invocation:**

```text
/aws --quick review this IAM policy for least privilege and surface any wildcards or missing condition keys
```

(paste the JSON inline)

**What happens:**

- The orchestrator classifies the prompt as a verb-of-inquiry plus a security artefact, escalates to full depth.
- `discovery` confirms the calling principal and target resources by calling `iam:get_managed_policy_document` (if the policy is managed) and `kb:search_documentation` for any service that has condition-key requirements (KMS, S3, IAM, STS, Secrets Manager…).
- `solution-architect` runs the `aws-waf-security-skill` against the policy: the 24 design questions and 24 anti-patterns. Wildcards (`Action: "*"`, `Resource: "*"` outside known-safe contexts) get flagged as findings; missing `aws:SourceArn` / `aws:SourceAccount` condition keys for cross-service confused-deputy risks get flagged as findings.
- `implementation` proposes a tightened policy, with the redaction policy from `aws-grounding-cache` applied so any inadvertent secret in the input does not land in the ledger.

**Why this is production-ready:**

- The 24-anti-pattern list is closed; the engineer can read the report and know the review is complete, not "model felt confident this time."
- `iam:simulate_principal_policy` is part of the IAM MCP roster — the implementation specialist may invoke it when the policy is non-trivial, returning a deterministic allow/deny per call/resource pair.
- The `aws-secret-scanner` hook blocks any accidental paste of an access key into the iteration loop at PreToolUse time.
- The `aws-api-write-guard` hook blocks any `aws iam put-role-policy` write verb that the implementation specialist might emit; the engineer applies the policy through their own IaC pipeline, not through the chat session.

---

## AWS-300 — pre-merge security audit of a service design

**Persona:** A senior platform engineer running the security gate on a payments service before merging the design PR.

**Trigger:** "We're about to merge `payments-service` design.md. Run the WAF security pillar end-to-end against it. I need findings I can paste into the security-review issue."

**Invocation:**

```text
/aws --deep run the WAF security pillar end-to-end against .claude/specs/payments-service/design.md and produce a findings list with severity and grounded citations
```

**What happens:**

- `discovery` reads the existing `requirements.md` and `design.md`, plus the per-component contracts under `.claude/specs/payments-service/contracts/`.
- `solution-architect` runs the full 24-question security pillar review: identity (root usage, MFA, IAM principal hygiene), data-at-rest encryption coverage, data-in-transit posture, network perimeter (public-facing surfaces, VPC flow logs), threat-detection wiring (GuardDuty, IAM Access Analyzer, Security Hub), incident-response runbook coverage, secrets management.
- For each question, the skill emits a finding tagged with severity (`critical`, `high`, `medium`, `low`) and a `<server>:<short-key>` citation. The finding either points at the design line that satisfies it or at the gap.
- `sec:CheckSecurityServices` and `sec:CheckStorageEncryption` provide grounded confirmation that the recommended controls are actually enabled on the target accounts (not just intended in the design).
- The findings list lands as a structured block that the engineer pastes into the security-review issue verbatim.

**Why this is production-ready:**

- Severity is not a feeling; the security-pillar skill ships the closed severity ladder, and gate-08 ensures the rule body stays within budget so the contract does not silently grow.
- Findings cite the design line they apply to and the `kb:` or `sec:` source they ground against. A reviewer can re-derive every finding.
- The merge contract resolves any disagreement between the security pillar and the cost pillar in security's favour: a finding the cost pillar wants to defer for budget reasons is not silently dropped — it surfaces as an Open Question.
- The `aws-secret-scanner` and `aws-api-write-guard` hooks remain on throughout; the audit cannot accidentally ship a credential or a write-verb call.

---

## AWS-500 — incident-driven multi-account identity-perimeter sweep

**Persona:** A staff security engineer responding to a confirmed access-key compromise in one of seven accounts. The blast-radius assessment must be defensible to legal and regulators, and the remediation plan must be auditable.

**Trigger:** "We confirmed an access-key compromise in account `123456789012` at 14:02 UTC. Tell me which principals could have assumed which roles cross-account, which resources have policies that this key could have touched, and produce a remediation plan that we can run through change management. Surface every place we are non-compliant with our own data-perimeter rules."

**Invocation:**

```text
/aws --deep blast-radius assessment for compromised access key in account 123456789012; trace every cross-account role assumption path; identify resources with resource-based policies the key could have touched; produce a remediation plan grounded against the WAF security pillar; surface every data-perimeter violation
```

**What happens:**

- `discovery` enumerates the principal's effective permissions via `iam:list_role_policies` + `iam:get_role_policy` + `iam:get_user_policy` + `iam:simulate_principal_policy`. Every API call is recorded in the grounding ledger with the redaction policy applied (no raw account IDs leak into a downstream artefact).
- `discovery` also calls `kb:search_documentation` for the canonical data-perimeter guard-rail patterns (SCPs blocking principals outside `aws:PrincipalOrgID`, resource-based policies blocking `aws:ResourceOrgID` violators, VPC endpoint policies blocking non-org principals).
- `solution-architect` runs the WAF security pillar's identity-perimeter section against the discovered surface, plus the network-perimeter section for any public-facing resource the key could have touched.
- `sec:GetSecurityFindings` is queried for any GuardDuty / Security Hub / IAM Access Analyzer finding scoped to the time window starting at 14:02 UTC.
- `sec:CheckNetworkSecurity` is run against the resources the principal could reach, surfacing data-in-transit posture gaps.
- `implementation` writes a remediation `tasks.md` ordered by severity: rotate the compromised key first, revoke role chains in priority order, deploy SCP / RCP guard-rails to close the gaps the sweep surfaced. Each task carries the citation that justifies it.
- Where two grounded sources contradict (e.g., a Security Hub finding says a bucket is public, but the bucket policy and Block Public Access settings say otherwise), the merge contract surfaces the conflict under `## Open Questions` instead of picking one — the engineer resolves it with a fresh, ledger-recorded retrieval.

**Why this is production-ready:**

- **Every remediation step is grounded.** Legal and regulators see citations, not "model said so." The `.grounding-ledger.json` captures every retrieval that backed the report; redaction is applied before insert.
- **Identity-perimeter discipline is contractual.** The security-pillar skill's anti-pattern list explicitly enumerates the perimeter mistakes the design must not make; the report against the live account is checked against the same closed list.
- **Conflict resolution is deterministic and auditable.** Where two security-grounded sources disagree, the disagreement is on the page; nothing is silently picked.
- **Hooks stay on through a high-stakes loop.** `aws-secret-scanner` blocks any inadvertent paste of post-rotation keys into the iteration; `aws-api-write-guard` blocks any `aws iam ...` or `aws ec2 revoke-security-group-...` write verb the implementation specialist might emit by accident — remediation always goes through change management, not through the chat.
- **No silent budget overflow.** If the IAM call budget is exhausted mid-sweep, the agent emits `budget-exhausted` and returns control rather than truncating the assessment. The engineer re-runs with a narrower scope and the cache reuses the prior facts.
