# Technology Stack

## Core Tools
- **Terragrunt**: >= 1.1.0 (stack dependencies, CAS, autoinclude)
- **Terraform/OpenTofu**: >= 1.5.0
- **AWS Provider**: >= 5.0

## Key Terragrunt 1.1 Features Used
- `terragrunt.stack.hcl` — stack composition with unit/stack blocks
- `autoinclude` — dynamic dependency injection and configuration patching
- Content Addressable Store (CAS) — source de-duplication across runs
- `include` blocks in stacks — shared stack configuration
- Change-based runs — only plan/apply changed units

## Project Conventions
- Remote state: S3 + DynamoDB locking
- Provider generation via `generate` blocks in common.hcl
- Environment selection: `TF_VAR_ENVIRONMENT` env var (default: dev)
- Module sources: Terraform Registry (`tfr:///`) or Git

## Code Quality
- Pre-commit: terragrunt-hclfmt, terraform-fmt, terraform-validate, tflint
- ThothCTL: scan iac, inventory, ai-review

## Common Commands
```bash
# Plan all stacks
terragrunt run --all -- plan

# Apply foundation layer
cd stacks/foundation && terragrunt run --all -- apply

# Generate stacks from terragrunt.stack.hcl
terragrunt stack generate

# Plan with specific environment
TF_VAR_ENVIRONMENT=prd terragrunt run --all -- plan
```
