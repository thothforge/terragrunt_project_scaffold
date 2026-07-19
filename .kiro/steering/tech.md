# Technology Stack

## Core Technologies

- **Terragrunt**: >= 1.1.0 — DRY orchestration with stack composition, CAS, and autoinclude
- **Terraform/OpenTofu**: >= 1.5.0 — Infrastructure provisioning and management
- **AWS**: Primary cloud provider (AWS Provider >= 5.0)
- **ThothCTL**: Project scaffolding, security scanning, AI review, and inventory

## Build System & Tools

- **Terragrunt**: Primary orchestration tool for Terraform
- **TFLint**: Terraform linting and validation
- **Pre-commit**: Git hooks for code quality (terragrunt-hclfmt, terraform-fmt, terraform-validate, tflint, shellcheck)
- **MkDocs**: Documentation generation
- **ThothCTL**: Security scanning (Checkov, Trivy, OPA), inventory (CycloneDX SBOM), AI review

## Key Terragrunt 1.1 Features Used

- `terragrunt.stack.hcl` — Stack composition with `unit` and `stack` blocks
- `autoinclude` — Dynamic dependency injection and configuration patching between units
- Content Addressable Store (CAS) — Source de-duplication (on by default, opt out with `--no-cas`)
- `include` blocks in stacks — Shared stack configuration inheritance
- `unit.X.path` references — Intra-stack path resolution for dependencies
- Change-based runs — Only plan/apply changed units for performance at scale
- `update_source_with_cas` — Makes generated stacks self-contained and portable

## Common Commands

### Environment Setup
```bash
# Set environment variable (required)
export TF_VAR_ENVIRONMENT=dev  # or qa, prd

# Initialize a stack
cd stacks/foundation/network/vpc
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply
```

### Stack Operations (Terragrunt 1.1)
```bash
# Generate stack units from terragrunt.stack.hcl
terragrunt stack generate

# Plan all stacks (with CAS de-duplication)
terragrunt run --all -- plan

# Apply foundation layer only
cd stacks/foundation && terragrunt run --all -- apply

# Plan with specific environment
TF_VAR_ENVIRONMENT=prd terragrunt run --all -- plan

# Disable CAS for a single run
terragrunt run --all --no-cas -- plan
```

### Multi-stack Operations
```bash
# Run command across all stacks
terragrunt run --all -- plan
terragrunt run --all -- apply
terragrunt run --all -- destroy

# Run command for specific layer
cd stacks/platform && terragrunt run --all -- plan
```

### Validation & Linting
```bash
# Run TFLint
tflint --recursive

# Run pre-commit hooks
pre-commit run --all-files

# Validate Terraform syntax
terragrunt validate

# ThothCTL security scan
thothctl scan iac -t checkov -t trivy

# ThothCTL inventory
thothctl inventory iac --check-versions
```

## Configuration Management

- **Remote State**: S3 backend with DynamoDB locking
- **Variable Files**: Hierarchical variable precedence (environments > common > stack > defaults)
- **Environment Selection**: `TF_VAR_ENVIRONMENT` env var (default: dev)
- **Module Sources**: Terraform Registry (`tfr:///`) preferred, Git for private modules
- **Templates**: ThothCTL templating via `.thothcf.toml` for project scaffolding

## Key Configuration Files

- `root.hcl`: Root Terragrunt configuration (remote state, common vars, environment tfvars)
- `common/common.hcl`: Shared locals and provider generation
- `common/common.tfvars`: Common variable values (project, environment, tags)
- `environments/{env}/*.tfvars`: Per-environment overrides by layer
- `stacks/{layer}/terragrunt.stack.hcl`: Stack composition with autoinclude dependencies
- `.thothcf.toml`: Project templating configuration
- `.tflint.hcl`: Linting rules and configuration
- `.pre-commit-config.yaml`: Git hooks for code quality
