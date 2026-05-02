# MCP server roster (v0.1.0)

Loaded on demand by the `aws-mcp-routing` skill. Authoritative source-of-truth for which servers exist, what they do, and what tools they expose. Mirrors `.mcp.json`.

## Server keys and metadata

| Key    | Logical name                | Transport | Package                                        | Version | `timeoutMs` | Category   |
| ------ | --------------------------- | --------- | ---------------------------------------------- | ------- | ----------- | ---------- |
| `kb`   | `aws-knowledge`             | http      | `https://knowledge-mcp.global.api.aws`         | 0.1.0   | 30000       | Docs       |
| `iac`  | `aws-iac`                   | stdio     | `awslabs.aws-iac-mcp-server`                   | 1.0.17  | 60000       | IaC        |
| `cost` | `aws-pricing`               | stdio     | `awslabs.aws-pricing-mcp-server`               | 1.0.28  | 30000       | Cost       |
| `sec`  | `well-architected-security` | stdio     | `awslabs.well-architected-security-mcp-server` | 0.1.7   | 60000       | Security   |
| `iam`  | `iam`                       | stdio     | `awslabs.iam-mcp-server`                       | 1.0.18  | 30000       | Security   |
| `cw`   | `cloudwatch`                | stdio     | `awslabs.cloudwatch-mcp-server`                | 0.0.26  | 30000       | Operations |

Version pins are mandatory and bumped via `feat(deps)` PRs. `timeoutMs` is per-call, not per-session.

## Per-server tool catalogue

Cached at `tests/gates/cache/tools-<key>.txt`; refreshed manually when a version pin moves.

### `kb` — aws-knowledge

Latest AWS documentation, API references, What's New entries, Well-Architected guidance. No authentication required; rate-limited.

Tools:

- `search_documentation` — full-text search across AWS docs.
- `read_documentation` — fetch a specific documentation page by URL.
- `recommend` — suggest related documentation.
- `list_regions` — enumerate AWS regions.
- `get_regional_availability` — check service availability per region.
- `retrieve_agent_sops` — retrieve agent standard operating procedures.

### `iac` — aws-iac

CloudFormation and CDK validation, scanning, samples.

Tools:

- `read_iac_documentation_page`
- `validate_cloudformation_template`
- `check_cloudformation_template_compliance`
- `troubleshoot_cloudformation_deployment`
- `search_cloudformation_documentation`
- `get_cloudformation_pre_deploy_validation_instructions`
- `search_cdk_documentation`
- `search_cdk_samples_and_constructs`
- `cdk_best_practices`

### `cost` — aws-pricing

Pricing API and cost estimation.

Tools:

- `analyze_cdk_project`
- `analyze_terraform_project`
- `get_pricing`
- `get_bedrock_patterns`
- `generate_cost_report`
- `get_pricing_service_codes`
- `get_pricing_service_attributes`

### `sec` — well-architected-security

WAF security findings, GuardDuty and Security Hub triage, encryption and network checks. Tool names use PascalCase per upstream package convention.

Tools:

- `CheckSecurityServices`
- `GetSecurityFindings`
- `GetStoredSecurityContext`
- `CheckStorageEncryption`
- `ListServicesInRegion`
- `CheckNetworkSecurity`

### `iam` — iam

First-class IAM read and simulate; least-privilege loop. Mutating IAM operations are gated by the `aws-api-write-guard` hook.

Tools:

- `list_users`, `get_user`, `create_user`, `delete_user`
- `list_roles`, `create_role`
- `list_groups`, `get_group`, `create_group`, `delete_group`
- `add_user_to_group`, `remove_user_from_group`
- `attach_group_policy`, `detach_group_policy`
- `attach_user_policy`, `detach_user_policy`
- `list_policies`
- `simulate_principal_policy`
- `put_user_policy`, `get_user_policy`, `delete_user_policy`, `list_user_policies`
- `put_role_policy`, `get_role_policy`, `delete_role_policy`, `list_role_policies`
- `create_access_key`, `delete_access_key`

### `cw` — cloudwatch

Post-deploy observability evidence: alarms, log queries, metric data.

Tools:

- `get_metric_data`, `get_metric_metadata`
- `get_recommended_metric_alarms`, `analyze_metric`
- `get_active_alarms`, `get_alarm_history`
- `describe_log_groups`, `analyze_log_group`
- `execute_log_insights_query`, `execute_cwl_insights_batch`
- `get_logs_insight_query_results`, `cancel_logs_insight_query`

## Reserved (v0.2 — do not call)

Four servers are reserved for v0.2. Routing to them at v0.1.0 is forbidden:

- `aws-api-mcp-server` (general AWS API operations)
- `amazon-bedrock-agentcore-mcp-server`
- `dynamodb-mcp-server`
- `aws-serverless-mcp-server`

A v0.2 PR will add these to `.mcp.json` with new short keys and update this roster.
