# Infrastructure as Code Composition Guidelines

## Overview
This document defines the official Terraform modules and composition patterns to be used in this project. All infrastructure stacks must follow these guidelines to ensure consistency, security, and maintainability.

## Official Provider Modules

### Approved Module Sources
Use only modules from these official and verified sources:

1. **terraform-aws-modules**: Official AWS modules namespace
   - Source: `terraform-aws-modules/{module-name}/aws`
   - All modules under this namespace are approved
   - Examples: `vpc`, `eks`, `iam`, `rds`, `s3-bucket`, etc.

2. **HashiCorp Verified**: Only when official AWS module unavailable
   - Must have "Verified" badge in Terraform Registry
   - Requires approval before use

3. **AWS Provider**: Direct resource usage when no module exists
   - Use official `hashicorp/aws` provider resources
   - Follow AWS best practices and security guidelines

## Module Source Format
Always use Terraform Registry format with version pinning:

```hcl
terraform {
  source = "tfr:///terraform-aws-modules/{module-name}/aws?version={version}"
}
```

**Example:**
```hcl
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.0.0"
}
```

## Version Management
- **Pin Major Versions**: Always specify exact versions for production
- **Update Strategy**: Test in dev → qa → stg → prod
- **Security Updates**: Apply security patches within 30 days
- **Version Matrix**: Maintain compatibility matrix in project documentation

## Stack Composition Rules

### 1. Module Selection Priority
1. **Official AWS Modules**: `terraform-aws-modules/*` (preferred)
2. **HashiCorp Verified**: Only if official AWS module unavailable
3. **Community Modules**: Avoid unless absolutely necessary
4. **Custom Modules**: Last resort, must be approved

### 2. Required Configuration Patterns

#### Locals Block
```hcl
locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_WORKSPACE", "dev")
}
```

#### Dependency Management
Use `dependency` blocks instead of `dependencies` for explicit output references:

```hcl
dependency "vpc" {
  config_path = "../../../foundation/network/vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
    private_subnets = ["subnet-mock1", "subnet-mock2"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}
```

#### Environment-Specific Configuration
Define environment variations using locals:

```hcl
locals {
  env_config = {
    dev = {
      create = true
      instance_type = "t3.medium"
      public_access = true
    }
    prod = {
      create = true
      instance_type = "m5.large"
      public_access = false
    }
  }
  
  workspace_config = lookup(local.env_config, local.environment, local.env_config.dev)
}
```

#### Naming Convention
```hcl
name = "${local.common_vars.locals.project}-${local.environment}-{resource-type}"
```

#### Tagging Strategy
```hcl
tags = merge(
  local.common_vars.locals.tags,
  {
    Name        = "${local.common_vars.locals.project}-${local.environment}-{resource}"
    Layer       = "{foundation|platform|application|observability}"
    Domain      = "{network|compute|storage|security|data}"
    Component   = "{specific-component}"
    Environment = local.environment
  }
)
```

### 3. Security Requirements

#### IAM Roles
- Use least privilege principle
- Attach only necessary AWS managed policies
- Avoid inline policies unless required
- Enable MFA for sensitive roles

#### Network Security
- Use security groups over NACLs
- Implement defense in depth
- Enable VPC Flow Logs
- Use private subnets for workloads

#### Data Protection
- Enable encryption at rest and in transit
- Use AWS KMS for key management
- Implement backup strategies
- Enable versioning for S3 buckets

## Agent Guidelines

### Stack Creation Rules
When creating new stacks, the agent must:

1. **Validate Module Source**: Ensure using approved modules from the list above
2. **Check Version Compatibility**: Use latest stable version unless specified
3. **Apply Naming Convention**: Follow project-environment-resource pattern
4. **Include Required Tags**: All mandatory tags must be present
5. **Configure Dependencies**: Explicitly declare all dependencies
6. **Add Documentation**: Include README.md with module purpose and usage

### Module Research Process
1. **Search Official Modules**: Always start with `terraform-aws-modules`
2. **Verify Module Compatibility**: Check Terraform and provider version requirements
3. **Review Module Documentation**: Understand inputs, outputs, and examples
4. **Select Appropriate Submodule**: Use specific submodules when available
5. **Use latest Version for new stack components**: Use the latest or more recent version published for each module

### Dependency Management Rules
1. **Use `dependency` blocks**: Never use `dependencies` for cross-stack references
2. **Include Mock Outputs**: Always provide mock outputs for safe planning
3. **Set Mock Strategy**: Use `mock_outputs_merge_strategy_with_state = "shallow"`
4. **Relative Paths**: Use relative paths from current stack location
5. **Output References**: Reference dependency outputs as `dependency.{name}.outputs.{output}`

### Validation Checklist
- [ ] Module source uses `tfr://` format
- [ ] Version is pinned to specific release
- [ ] All required inputs are provided
- [ ] Naming follows project conventions
- [ ] Tags include all mandatory fields
- [ ] Dependencies are explicitly declared with `dependency` blocks
- [ ] Mock outputs are provided for all dependencies
- [ ] Environment-specific configuration uses locals pattern
- [ ] Security best practices are followed

## Examples

### Foundation Layer - VPC Stack
```hcl
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.0.0"
}

inputs = {
  name = "${local.common_vars.locals.project}-${local.environment}-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["${local.common_vars.locals.deployment_region}a", "${local.common_vars.locals.deployment_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  enable_dns_hostnames = true
  
  tags = merge(local.common_vars.locals.tags, {
    Layer = "foundation"
    Domain = "network"
    Component = "vpc"
  })
}
```

### Foundation Layer - IAM Role Stack
```hcl
terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-role?version=6.2.1"
}

inputs = {
  role_name = "${local.common_vars.locals.project}-${local.environment}-eks-role"
  
  trusted_role_services = ["eks.amazonaws.com"]
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
  
  tags = merge(local.common_vars.locals.tags, {
    Layer = "foundation"
    Domain = "iam"
    Component = "roles"
  })
}
```

### Platform Layer - EKS Stack
```hcl
terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=21.0.0"
}

dependencies {
  paths = [
    "../../../foundation/network/vpc",
    "../../../foundation/iam/roles"
  ]
}

inputs = {
  cluster_name    = "${local.common_vars.locals.project}-${local.environment}-eks"
  cluster_version = "1.28"
  
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets
  
  tags = merge(local.common_vars.locals.tags, {
    Layer = "platform"
    Domain = "containers"
    Component = "eks-control-plane"
  })
}
```

## Prohibited Practices

### ❌ Avoid These Patterns
- Using unverified community modules
- Hardcoded values instead of variables
- Missing version constraints
- Inline policies for IAM roles
- Public subnets for workloads
- Unencrypted storage resources
- Missing or incomplete tags

### ✅ Required Practices
- Official AWS modules only
- Version pinning for all modules
- Consistent naming conventions
- Comprehensive tagging strategy
- Explicit dependency declarations
- Security-first configurations
- Complete documentation

## Compliance & Governance

### Module Approval Process
1. **Research**: Identify official module for use case
2. **Validation**: Verify module meets security requirements
3. **Testing**: Test in development environment
4. **Documentation**: Update this guideline if new module approved
5. **Implementation**: Deploy following established patterns

### Regular Reviews
- **Monthly**: Review for new module versions
- **Quarterly**: Security and compliance audit
- **Annually**: Architecture and pattern review

This guideline ensures consistent, secure, and maintainable infrastructure code across all environments and teams.
