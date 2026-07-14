---
paths:
  - "stacks/**"
  - "common/**"
---

# IaC Composition Rules for Terragrunt

## Module Sources (Priority Order)

1. `terraform-aws-modules/*` — REQUIRED as first choice
2. `hashicorp/aws` provider resources — ALLOWED
3. HashiCorp Verified modules — REQUIRES approval

Format: `tfr:///terraform-aws-modules/{module}/aws?version={exact-version}`

## Version Pinning

- All modules MUST specify exact versions (e.g., `?version=5.0.0`)
- Loose constraints (`>=`, `~>`) are PROHIBITED
- Check latest stable version before suggesting

## Terragrunt.hcl Pattern

Every `terragrunt.hcl` must include:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_WORKSPACE", "dev")
}

dependency "name" {
  config_path = "relative/path/to/dependency"
  mock_outputs = {
    output_key = "mock-value"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}
```

- Use `dependency` blocks, NEVER `dependencies` (deprecated)
- All dependencies MUST have `mock_outputs` for safe `plan` without apply

## Mandatory Tags

```hcl
tags = merge(local.common_vars.locals.tags, {
  Name        = "${local.common_vars.locals.project}-${local.environment}-{resource}"
  Layer       = "{foundation|platform|application|observability}"
  Domain      = "{network|compute|storage|security|data}"
  Component   = "{specific-component}"
  Environment = local.environment
})
```

## Security Requirements

- Encryption at rest: ALWAYS enabled
- Workloads: private subnets only
- IAM: least privilege, no inline `*` policies
- No hardcoded secrets, credentials, or access keys
- Security groups: no `0.0.0.0/0` ingress on sensitive ports

## Layer Architecture

Dependency direction (top-down only):
- **Foundation** (VPC, IAM) → no upward deps
- **Platform** (EKS, RDS) → depends on Foundation
- **Application** (ALB, compute) → depends on Foundation/Platform
- **Observability** (monitoring) → depends on any lower layer

Cross-layer upward dependencies are PROHIBITED.

## Prohibited Practices

- Using `dependencies` block (use `dependency` with mock_outputs)
- Loose version constraints on modules
- Hardcoded environment values (use locals + workspace)
- Resources without required tags
- Public subnets for workloads
- Unencrypted storage or state
- Skipping documentation (every stack needs README.md)

## Naming Convention

Resources: `{project}-{environment}-{resource-type}`
Implementation: `"${local.common_vars.locals.project}-${local.environment}-{type}"`
