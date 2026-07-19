# Project Structure

## Directory Organization

The project follows a layered architecture with clear separation of concerns:

```
├── stacks/                           # Infrastructure stacks organized by layers
│   ├── foundation/                   # Base infrastructure (VPC, IAM, Security)
│   │   ├── terragrunt.stack.hcl     # Stack composition: vpc, iam_roles, security_groups
│   │   ├── network/
│   │   │   ├── vpc/                 # VPC, subnets, NAT, routing
│   │   │   └── security-groups/     # Security group definitions
│   │   └── iam/
│   │       ├── roles/               # Service roles
│   │       └── policies/            # Custom policies
│   ├── platform/                     # Shared services (EKS, RDS, ElastiCache)
│   │   ├── terragrunt.stack.hcl     # Stack composition: eks, ecr, rds, elasticache
│   │   ├── containers/
│   │   │   ├── eks/                 # EKS cluster
│   │   │   └── ecr/                 # Container registry
│   │   └── data/
│   │       ├── rds/                 # Relational databases
│   │       └── elasticache/         # Cache clusters
│   ├── application/                  # Application-specific infrastructure
│   │   ├── terragrunt.stack.hcl     # Stack composition: alb, asg, s3, efs
│   │   ├── compute/
│   │   │   ├── alb/                 # Application load balancer
│   │   │   └── asg/                 # Auto scaling groups
│   │   └── storage/
│   │       ├── s3/                  # Object storage
│   │       └── efs/                 # Elastic file system
│   └── observability/                # Monitoring and logging
│       ├── terragrunt.stack.hcl     # Stack composition: cloudwatch, prometheus
│       └── monitoring/
│           ├── cloudwatch/          # CloudWatch logs and alarms
│           └── prometheus/          # Managed Prometheus
├── common/                           # Shared configuration and variables
│   ├── common.hcl                   # Locals, provider generation, tags
│   ├── common.tfvars                # Common variable values
│   └── variables.tf                 # Shared variable definitions
├── environments/                     # Environment-specific configurations
│   ├── dev/                         # Development overrides
│   ├── qa/                          # QA overrides
│   └── prd/                         # Production overrides
├── docs/                             # Project documentation
│   └── catalog/                     # Backstage catalog and docs
├── root.hcl                          # Root Terragrunt config (state, vars, env)
├── .thothcf.toml                     # Template parameters
├── .kiro/                            # Kiro AI assistant configurations
│   ├── steering/                    # Project context for AI
│   ├── agents/                      # Agent definitions
│   ├── settings/                    # MCP and tool settings
│   └── skills/                      # Reusable skills
└── .pre-commit-config.yaml           # Git hooks
```

## Stack Composition (Terragrunt 1.1)

Each layer has a `terragrunt.stack.hcl` that defines its units and their dependencies:

```hcl
# stacks/platform/terragrunt.stack.hcl
unit "eks" {
  source = "tfr:///terraform-aws-modules/eks/aws?version=20.31.0"
  path   = "containers/eks"

  autoinclude {
    dependency "vpc" {
      config_path = "../../foundation/network/vpc"
    }
    inputs = {
      vpc_id     = dependency.vpc.outputs.vpc_id
      subnet_ids = dependency.vpc.outputs.private_subnets
    }
  }
}
```

### Stack File Conventions
- One `terragrunt.stack.hcl` per layer (foundation, platform, application, observability)
- Units reference Terraform Registry modules via `tfr:///`
- Cross-layer dependencies use `autoinclude` with relative `config_path`
- Intra-layer dependencies use `unit.X.path` for path resolution

## Unit Structure Convention

Each unit (directory within a layer) follows a standardized structure:

```
unit-name/
├── terragrunt.hcl          # Terragrunt configuration (root include, locals)
├── main.tf                 # Main Terraform resources (optional if source in stack)
├── variables.tf            # Input variable definitions
├── outputs.tf              # Output value definitions
└── versions.tf             # Provider version constraints (optional)
```

**Note**: When a unit's module source and inputs are fully defined in the parent `terragrunt.stack.hcl` via `autoinclude`, the unit's `terragrunt.hcl` only needs the root include and locals. Stack-level configuration is merged automatically.

## Naming Conventions

### Stack Paths
```
stacks/{layer}/{domain}/{service}/
```

**Examples:**
- `stacks/foundation/network/vpc/`
- `stacks/platform/containers/eks/`
- `stacks/application/compute/alb/`
- `stacks/observability/monitoring/cloudwatch/`

### Layers (in dependency order)
1. **foundation**: Core infrastructure (VPC, IAM, Security Groups)
2. **platform**: Shared services (EKS, RDS, ElastiCache, ECR)
3. **application**: Application-specific resources (ALB, ASG, S3, EFS)
4. **observability**: Monitoring and logging (CloudWatch, Prometheus)

## Dependency Rules

- **Foundation** → Platform → Application → Observability
- Units within a layer can depend on other units in the same layer
- Units can depend on units in lower layers (platform → foundation)
- Never depend on higher layers (foundation ✗→ application)
- Cross-layer dependencies declared via `autoinclude` in `terragrunt.stack.hcl`
- Intra-layer dependencies declared via `dependency` blocks in `terragrunt.hcl`
- All `dependency` blocks MUST include `mock_outputs` with realistic values

## Configuration Hierarchy

### Variable Precedence (highest to lowest)
1. Environment-specific files (`environments/{env}/*.tfvars`)
2. Common variables (`common/common.tfvars`)
3. Stack-specific inputs (from `terragrunt.stack.hcl` autoinclude)
4. Unit-specific inputs (from `terragrunt.hcl`)
5. Default values in `variables.tf`

### Key Files
- `root.hcl`: Root Terragrunt config — remote state, common vars, environment tfvars
- `common/common.hcl`: Shared locals, provider generation, tag definitions
- `common/common.tfvars`: Common variable values for all stacks
- `environments/{env}/*.tfvars`: Per-environment overrides by layer
- `stacks/{layer}/terragrunt.stack.hcl`: Stack composition with autoinclude

## Required Tags

All resources must include these tags:
```hcl
tags = {
  Project     = var.project
  Environment = var.environment
  Owner       = var.owner
  ManagedBy   = "Tofu-Terragrunt"
  Framework   = "DevSecOps-IaC"
}
```

## File Naming Standards

- Use lowercase with hyphens for directories
- Use snake_case for Terraform files (`.tf`)
- Use descriptive names that indicate purpose
- Keep stack/unit names concise but clear
- Stack files always named `terragrunt.stack.hcl`
- Unit configs always named `terragrunt.hcl`
