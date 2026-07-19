# Infrastructure as Code Composition Rules

These are **mandatory rules** that must be followed for all Terraform/Terragrunt operations in this project.

## Stack File Structure (R001)

Each unit **MUST** contain these required files:
- `terragrunt.hcl` - Terragrunt orchestration with root include and locals
- `main.tf` - Terraform module configurations (optional if source defined in stack)
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output value definitions

Each layer **MUST** contain:
- `terragrunt.stack.hcl` - Stack composition with unit definitions and autoinclude dependencies

## Stack Composition Rules (R001.1 — Terragrunt 1.1)

### terragrunt.stack.hcl Requirements:
- One per layer (foundation, platform, application, observability)
- All units in the layer MUST be defined in the stack file
- Cross-layer dependencies MUST use `autoinclude` blocks
- Module sources MUST use `tfr:///` for registry modules with pinned versions

### autoinclude Pattern:
```hcl
unit "service_name" {
  source = "tfr:///terraform-aws-modules/module/aws?version=X.Y.Z"
  path   = "domain/service-name"

  autoinclude {
    dependency "upstream" {
      config_path = "../../layer/domain/service"
    }
    inputs = {
      output_var = dependency.upstream.outputs.output_var
    }
  }
}
```

### Stack Dependency Direction:
- ✅ platform → foundation (allowed)
- ✅ application → foundation, platform (allowed)
- ✅ observability → platform (allowed)
- ❌ foundation → platform, application, observability (BLOCKED)
- ❌ platform → application (BLOCKED)

## Module Source Standards (R002-R003)

### Approved Module Sources (in order of preference):
1. **terraform-aws-modules** (official AWS modules) - `terraform-aws-modules/vpc/aws`
2. **terraform-aws-ia-modules** (official AWS IA modules) - `aws-ia/`
3. **Git repositories** - `git::https://github.com/...`
4. **Local modules** - `./modules/module-name` (last resort only)

### Version Pinning Required:
```hcl
# In terragrunt.stack.hcl
unit "vpc" {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.16.0"  # Exact version required
  path   = "network/vpc"
}
```

## Terragrunt Unit Configuration Pattern (R004)

**Required terragrunt.hcl structure for units:**
```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_VAR_ENVIRONMENT", "dev")
}

# When unit has dependencies not covered by terragrunt.stack.hcl autoinclude:
dependency "vpc" {
  config_path = "../../../foundation/network/vpc"
  mock_outputs = {
    vpc_id = "vpc-mock-12345"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  tags = merge(
    local.common_vars.locals.tags,
    {
      Layer       = "platform"
      Domain      = "containers"
      Component   = "eks"
      Environment = local.environment
    }
  )
}
```

## Environment Configuration Pattern (R004.1)

All values for each environment must be defined in the respective `.tfvars` file in `environments/` folder:
```bash
environments/
├── dev/
│   ├── applications.tfvars
│   ├── foundations.tfvars
│   ├── observability.tfvars
│   └── platform.tfvars
├── prd/
│   ├── applications.tfvars
│   ├── foundations.tfvars
│   ├── observability.tfvars
│   └── platform.tfvars
└── qa/
    ├── applications.tfvars
    ├── foundations.tfvars
    ├── observability.tfvars
    └── platform.tfvars
```

Environment is selected via `TF_VAR_ENVIRONMENT` (default: `dev`).

## Dependency Management (R005)

All dependencies **MUST** include:
- `config_path` with relative path
- `mock_outputs` with realistic values
- `mock_outputs_merge_strategy_with_state = "shallow"`

For Terragrunt 1.1 stacks, prefer `autoinclude` in `terragrunt.stack.hcl` over `dependency` blocks in individual `terragrunt.hcl` files for cross-layer dependencies.

## Mandatory Tagging (R006)

**Required tags for ALL resources:**
```hcl
tags = {
  Project     = var.project
  Environment = local.environment
  Owner       = var.owner
  ManagedBy   = "Tofu-Terragrunt"
  Framework   = "DevSecOps-IaC"
  Layer       = "foundation|platform|application|observability"
  Domain      = "network|iam|containers|data|compute|storage|monitoring"
  Component   = "<service-name>"
}
```

## Security Requirements (R008-R010)

### IAM Security:
- Use least privilege principle
- Attach only necessary AWS managed policies
- Avoid inline policies unless required
- Enable MFA for sensitive roles

### Network Security:
- Use security groups over NACLs
- Implement defense in depth
- Enable VPC Flow Logs
- Use private subnets for workloads

### Data Protection:
- Enable encryption at rest and in transit
- Use AWS KMS for key management
- Implement backup strategies
- Enable versioning for S3 buckets

## CAS and Source Management (R011 — Terragrunt 1.1)

- CAS is enabled by default — do NOT disable it in CI/CD
- Use `update_source_with_cas = true` for portable stack generation
- Module sources MUST be versioned (CAS caches by content hash)
- Never use `ref=main` or `ref=latest` — always pin to specific versions or tags

## Local Module Standards (R013)

When terraform-aws-modules cannot fulfill requirements:

**Required local module structure:**
```
modules/
├── {module-name}/
│   ├── main.tf          # Resource definitions
│   ├── variables.tf     # Input variable definitions
│   ├── outputs.tf       # Output value definitions
│   ├── versions.tf      # Provider version constraints
│   └── README.md        # Module documentation
```

**Local module requirements:**
- Complete file structure
- Provider version constraints
- All variables documented with descriptions and types
- Tags variable with default empty map
- Comprehensive README.md with examples

## Prohibited Practices

### ❌ Never Do:
- Use unverified community modules
- Hardcode values instead of variables
- Skip version constraints
- Create inline IAM policies
- Put workloads in public subnets
- Use unencrypted storage
- Skip mandatory tags
- Depend on higher layers (e.g., foundation → application)
- Use `ref=main` or floating versions in sources
- Disable CAS in CI/CD pipelines

### ✅ Always Do:
- Use terraform-aws-modules first
- Pin exact versions in `terragrunt.stack.hcl`
- Include complete unit structure
- Follow terragrunt patterns (root include, locals, dependency with mocks)
- Apply comprehensive tagging with Layer/Domain/Component
- Use `autoinclude` for cross-layer dependencies
- Implement security-first configurations
- Keep environments/ tfvars updated per layer

## Enforcement Actions

- **BLOCK**: Incomplete structure, security violations, missing versions, wrong dependency direction
- **REQUIRE**: Proper terragrunt config, dependency mocks, mandatory tags, stack files per layer
- **WARN**: Outdated versions, missing documentation, unused variables

## Module Selection Priority

1. **First**: terraform-aws-modules (official AWS modules)
2. **Second**: Well-maintained community modules (verified providers)
3. **Last**: Local modules (justify why terraform-aws-modules insufficient)

These rules ensure consistent, secure, and maintainable infrastructure code at scale.
