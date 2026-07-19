# Terragrunt Project Scaffold

**Stack-based AWS infrastructure composition with Terragrunt 1.1** — a production-ready template for managing multi-layer cloud infrastructure using Terragrunt's native stack orchestration, `autoinclude` dependency injection, and Content-Addressable Storage (CAS).

## Overview

This scaffold leverages Terragrunt 1.1's `terragrunt.stack.hcl` files to declaratively compose infrastructure layers as directed acyclic graphs (DAGs). Each stack defines its units and their inter-dependencies, eliminating manual `dependency` blocks and enabling automated cross-stack wiring.

Key design principles:

- **Layered architecture** — Foundation → Platform → Application → Observability
- **Stack-based composition** — Each layer is a self-contained `terragrunt.stack.hcl` with explicit unit definitions
- **Autoinclude dependencies** — Cross-unit and cross-stack references are resolved automatically
- **Environment-driven configuration** — `TF_VAR_ENVIRONMENT` selects per-environment `.tfvars` overlays
- **Template-ready** — ThothCTL parameterization for scaffolding new projects from this template

## Project Structure

```
#{project_name}#/
├── root.hcl                          # Root Terragrunt config (remote state, providers)
├── common/
│   ├── common.hcl                    # Shared locals, tags, provider config
│   ├── common.tfvars                 # Common variable values
│   └── variables.tf                  # Shared variable definitions
├── environments/                     # Per-environment variable overlays
│   ├── dev/
│   │   ├── foundations.tfvars
│   │   ├── platform.tfvars
│   │   ├── applications.tfvars
│   │   └── observability.tfvars
│   ├── qa/
│   │   └── ...
│   └── prd/
│       └── ...
├── stacks/
│   ├── foundation/                   # Core infrastructure layer
│   │   ├── terragrunt.stack.hcl      # Stack composition (VPC, IAM, SGs)
│   │   ├── network/
│   │   │   ├── vpc/terragrunt.hcl
│   │   │   └── security-groups/terragrunt.hcl
│   │   └── iam/
│   │       ├── roles/terragrunt.hcl
│   │       └── policies/
│   ├── platform/                     # Shared services layer
│   │   ├── terragrunt.stack.hcl      # Stack composition (EKS, ECR, RDS, ElastiCache)
│   │   ├── containers/
│   │   │   ├── eks/terragrunt.hcl
│   │   │   └── ecr/terragrunt.hcl
│   │   └── data/
│   │       ├── rds/terragrunt.hcl
│   │       └── elasticache/terragrunt.hcl
│   ├── application/                  # Application-specific layer
│   │   ├── terragrunt.stack.hcl      # Stack composition (ALB, ASG, S3, EFS)
│   │   ├── compute/
│   │   │   ├── alb/terragrunt.hcl
│   │   │   └── asg/terragrunt.hcl
│   │   └── storage/
│   │       ├── s3/terragrunt.hcl
│   │       └── efs/terragrunt.hcl
│   └── observability/                # Monitoring and logging layer
│       ├── terragrunt.stack.hcl      # Stack composition (CloudWatch, Prometheus)
│       └── monitoring/
│           ├── cloudwatch/terragrunt.hcl
│           └── prometheus/terragrunt.hcl
├── docs/                             # Documentation and Backstage catalog
├── .thothcf.toml                     # ThothCTL template parameters
├── .pre-commit-config.yaml           # Pre-commit hooks
├── .tflint.hcl                       # TFLint configuration
├── .gitignore                        # Git ignore rules
└── LICENSE                           # Apache 2.0
```

## Quick Start

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Terragrunt](https://terragrunt.gruntwork.io/) | **≥ 1.1.0** | Stack orchestration and HCL composition |
| [OpenTofu](https://opentofu.org/) or [Terraform](https://www.terraform.io/) | ≥ 1.6 | Infrastructure provisioning |
| [AWS CLI](https://aws.amazon.com/cli/) | ≥ 2.x | AWS authentication and configuration |
| [ThothCTL](https://pypi.org/project/thothctl/) | ≥ 0.22 | Template scaffolding and IaC governance |
| [TFLint](https://github.com/terraform-linters/tflint) | latest | Linting (optional) |
| [Pre-commit](https://pre-commit.com/) | latest | Git hooks (optional) |

### 1. Scaffold from Template

```bash
# Using ThothCTL
thothctl init project --name my-infra --template terragrunt-aws

# Or clone directly
git clone <repo-url> my-infra && cd my-infra
```

### 2. Configure Parameters

Edit `.thothcf.toml` or run ThothCTL's interactive setup to fill in template values (project name, region, backend bucket, etc.).

### 3. Set Environment

```bash
export TF_VAR_ENVIRONMENT=dev   # dev | qa | prd
```

### 4. Deploy a Stack

```bash
cd stacks/foundation

# Plan all units in the foundation stack
terragrunt run-all plan

# Apply the foundation layer
terragrunt run-all apply
```

### 5. Deploy All Stacks (respects dependency order)

```bash
cd stacks
terragrunt run-all apply
```

## Stack Composition (Terragrunt 1.1)

### `terragrunt.stack.hcl`

Each layer defines a **stack file** that declares its units and their dependency graph. Terragrunt 1.1 reads these files to orchestrate plan/apply order automatically.

```hcl
# stacks/foundation/terragrunt.stack.hcl

unit "vpc" {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.16.0"
  path   = "network/vpc"
}

unit "security_groups" {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.2.0"
  path   = "network/security-groups"

  autoinclude {
    dependency "vpc" {
      config_path = unit.vpc.path
    }
    inputs = {
      vpc_id = dependency.vpc.outputs.vpc_id
    }
  }
}
```

### `autoinclude` — Dependency Injection

The `autoinclude` block within a unit:

1. **Declares dependencies** via `dependency` sub-blocks with `config_path` pointing to the upstream unit
2. **Injects inputs** automatically from dependency outputs into the unit's `inputs`
3. **Eliminates boilerplate** — no need for manual `dependency` blocks or `mock_outputs` in each unit's `terragrunt.hcl`

Cross-stack references use relative paths:

```hcl
# In platform stack, referencing foundation stack
autoinclude {
  dependency "vpc" {
    config_path = "../../foundation/network/vpc"
  }
  inputs = {
    vpc_id     = dependency.vpc.outputs.vpc_id
    subnet_ids = dependency.vpc.outputs.private_subnets
  }
}
```

### Content-Addressable Storage (CAS)

Terragrunt 1.1 caches module sources using content-addressable storage, reducing redundant downloads and accelerating `init` across units that share the same module version.

### Unit `terragrunt.hcl` Files

Each unit directory contains a minimal `terragrunt.hcl` that includes the root configuration. Source and dependency inputs are injected by the stack file's `autoinclude`:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_VAR_ENVIRONMENT", "dev")
}

# Module source and inputs are injected by terragrunt.stack.hcl autoinclude
# Add stack-specific overrides here
```

Units with complex configuration (e.g., VPC CIDR ranges, EKS cluster settings) define their own `inputs` block which merges with the autoinclude-injected inputs.

## Environment Management

Environments are controlled via the `TF_VAR_ENVIRONMENT` variable and per-environment `.tfvars` overlays.

### How It Works

1. `root.hcl` injects environment-specific tfvars via `optional_var_files`:
   ```hcl
   optional_var_files = [
     "${get_terragrunt_dir()}/overwrite.auto.tfvars",
     "${get_repo_root()}/environments/${get_env("TF_VAR_ENVIRONMENT", "dev")}/foundations.tfvars",
     "${get_repo_root()}/environments/${get_env("TF_VAR_ENVIRONMENT", "dev")}/platform.tfvars",
     "${get_repo_root()}/environments/${get_env("TF_VAR_ENVIRONMENT", "dev")}/applications.tfvars",
     "${get_repo_root()}/environments/${get_env("TF_VAR_ENVIRONMENT", "dev")}/observability.tfvars",
   ]
   ```

2. Each environment directory contains layer-specific overrides:
   ```
   environments/
   ├── dev/     # Development — permissive, cost-optimized
   ├── qa/      # QA — production-like, smaller scale
   └── prd/     # Production — hardened, HA, full scale
   ```

3. Switch environments:
   ```bash
   export TF_VAR_ENVIRONMENT=prd
   terragrunt run-all plan
   ```

## Dependency Graph

Infrastructure deploys in strict layer order. Within each layer, Terragrunt resolves the unit DAG from `autoinclude` declarations.

```
┌─────────────────────────────────────────────────────────────────┐
│                         OBSERVABILITY                            │
│   CloudWatch ─── Prometheus (← EKS)                            │
└──────────────────────────────┬──────────────────────────────────┘
                               │ depends on
┌──────────────────────────────▼──────────────────────────────────┐
│                         APPLICATION                              │
│   ALB (← VPC, SGs) ─── ASG (← VPC, ALB)                        │
│   S3 ─── EFS (← VPC)                                           │
└──────────────────────────────┬──────────────────────────────────┘
                               │ depends on
┌──────────────────────────────▼──────────────────────────────────┐
│                          PLATFORM                                │
│   EKS (← VPC, IAM) ─── ECR                                     │
│   RDS (← VPC) ─── ElastiCache (← VPC)                          │
└──────────────────────────────┬──────────────────────────────────┘
                               │ depends on
┌──────────────────────────────▼──────────────────────────────────┐
│                         FOUNDATION                               │
│   VPC ─── IAM Roles                                             │
│   Security Groups (← VPC)                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Deployment Order

```bash
# Full deploy (Terragrunt resolves order automatically)
cd stacks && terragrunt run-all apply

# Or deploy layer-by-layer for more control
cd stacks/foundation  && terragrunt run-all apply
cd stacks/platform    && terragrunt run-all apply
cd stacks/application && terragrunt run-all apply
cd stacks/observability && terragrunt run-all apply
```

## ThothCTL Integration

This scaffold is a [ThothCTL](https://thothforge.github.io/thothctl/) template. ThothCTL provides:

- **Template scaffolding** — `thothctl init project` populates all `#{placeholder}#` values
- **Security scanning** — `thothctl scan iac -t checkov -t trivy --enforcement hard`
- **Infrastructure inventory** — `thothctl inventory iac --check-versions` generates CycloneDX SBOM
- **Cost analysis** — `thothctl check iac -type cost-analysis --recursive`
- **Drift detection** — `thothctl check iac -type drift --recursive`
- **AI code review** — `thothctl ai-review analyze -d ./stacks -p ollama`
- **Dashboard** — `thothctl dashboard launch` for unified visibility

### MCP Server

Run the ThothCTL MCP server for AI assistant integration:

```bash
thothctl mcp
```

## Template Parameters

Parameters defined in `.thothcf.toml` are replaced during scaffolding:

| Parameter | Description | Default | Validation |
|-----------|-------------|---------|------------|
| `project_name` | Project identifier | `test-wrapper` | `^[a-zA-Z0-9\-]+$` |
| `deployment_region` | AWS deployment region | `us-east-2` | `^[a-z]{2}-[a-z]{4,10}-\d$` |
| `backend_bucket` | S3 bucket for Terraform state | `test-wrapper-tfstate` | S3 naming rules |
| `backend_region` | S3 backend region | `us-east-2` | `^[a-z]{2}-[a-z]{4,10}-\d$` |
| `backend_dynamodb` | DynamoDB lock table | `db-terraform-lock` | `^[a-zA-Z0-9_.-]{3,255}$` |
| `environment` | Initial environment | `dev` | `(dev\|qa\|stg\|test\|prod)` |
| `cloud_provider` | Cloud provider | `aws` | `(aws\|azure\|oci\|gcp)` |
| `deployment_profile` | AWS CLI profile | `default` | `^[a-zA-Z0-9_.-]{3,255}$` |
| `backend_profile` | S3 state profile | `default` | `^[a-zA-Z0-9_.-]{3,255}$` |
| `owner` | Team/role owner | `thothctl` | `^[a-zA-Z0-9\-]+$` |
| `client` | Client/area | `thothctl` | `^[a-zA-Z0-9\-]+$` |

## Development Workflow

### Pre-commit Hooks

Install and activate:

```bash
pip install pre-commit
pre-commit install
```

Configured hooks (`.pre-commit-config.yaml`):

| Hook | Purpose |
|------|---------|
| `terragrunt-hclfmt` | Format all `.hcl` files |
| `terraform-fmt` | Format `.tf` files |
| `terraform-validate` | Validate Terraform syntax |
| `tflint` | Lint Terraform code |
| `shellcheck` | Lint shell scripts |

### Workflow

```bash
# 1. Set target environment
export TF_VAR_ENVIRONMENT=dev

# 2. Create feature branch
git checkout -b feat/add-redis-cluster

# 3. Make changes (e.g., add unit to platform stack)
#    Edit stacks/platform/terragrunt.stack.hcl

# 4. Validate
pre-commit run --all-files
cd stacks/platform && terragrunt run-all validate

# 5. Plan
terragrunt run-all plan

# 6. Apply in dev
terragrunt run-all apply

# 7. Security scan
thothctl scan iac -t checkov -t trivy

# 8. Commit and push
git add -A && git commit -m "feat(platform): add Redis ElastiCache cluster"
git push -u origin feat/add-redis-cluster
```

### Adding a New Unit

1. Add the unit block to the appropriate `terragrunt.stack.hcl`
2. Create the unit directory with a minimal `terragrunt.hcl` stub
3. Add environment-specific overrides in `environments/<env>/<layer>.tfvars` if needed
4. Run `terragrunt run-all plan` to verify the dependency graph

## Remote State

State is stored in S3 with DynamoDB locking (configured in `root.hcl`):

```
s3://#{backend_bucket}#/#{project_name}#/<relative-path>/terraform.tfstate
```

Each unit gets an isolated state file keyed by its path relative to the repository root.

## License

This project is licensed under the [Apache License 2.0](LICENSE).
