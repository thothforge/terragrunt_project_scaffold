# Terragrunt Project Scaffold

Production-ready Terragrunt template for AWS infrastructure with GitOps integration and multi-environment support.

## Project Structure

```
root.hcl                         # Root Terragrunt config (remote state, common inputs)
common/
├── common.hcl                   # Shared locals: project, region, backend, tags
└── variables.tf                 # Shared variable definitions
stacks/
├── foundation/                  # Core: VPC, IAM roles
│   ├── network/vpc/
│   └── iam/roles/
├── platform/                    # Shared services: EKS, databases
│   ├── containers/eks-control-plane/
│   └── data/
├── application/                 # App-specific: ALB, compute, storage
│   ├── compute/alb/
│   └── storage/
└── observability/               # Monitoring and logging
    └── monitoring/
```

Each service directory contains: `terragrunt.hcl`, `main.tf`, `variables.tf`, `outputs.tf`.

## Technology

- **Terragrunt** >= 0.45.0
- **Terraform** >= 1.0
- **AWS CLI** configured with profiles
- **TFLint** with AWS ruleset
- **Pre-commit** hooks for formatting/validation

## Key Rules

### Module Sources
Use `terraform-aws-modules` as first choice:
```hcl
terraform {
  source = "tfr:///terraform-aws-modules/{module}/aws?version={exact-version}"
}
```

### Version Pinning
Exact versions required — no `>=` or `~>` constraints.

### Dependency Pattern
```hcl
dependency "vpc" {
  config_path = "../../../foundation/network/vpc"
  mock_outputs = {
    vpc_id          = "vpc-mock"
    private_subnets = ["subnet-mock1", "subnet-mock2"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}
```

### Mandatory Tags
All resources must include: `Name`, `Layer`, `Domain`, `Component`, `Environment`, plus common tags from `common.hcl`.

### Remote State
S3 bucket + DynamoDB table for locking. Configured in `root.hcl`.

### Layer Dependencies
Foundation → Platform → Application → Observability (top-down only).

## Environments

Workspace-based: `dev`, `qa`, `stg`, `test`, `prod`. Set via `TF_WORKSPACE` env var.

## ThothCTL Template

This is a ThothCTL template project. Configuration in `.thothcf.toml` uses `#{placeholder}#` syntax for template parameters (e.g., `#{project_name}#`, `#{deployment_region}#`).

## Commands

```bash
# Plan a stack
cd stacks/foundation/network/vpc && terragrunt plan

# Apply all stacks
terragrunt run-all apply

# Validate
pre-commit run --all-files
tflint --recursive

# Security scan (via ThothCTL)
thothctl scan iac -t checkov -t trivy
```
