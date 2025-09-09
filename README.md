# Terragrunt Project Scaffold

A production-ready Terragrunt template for AWS infrastructure deployment with GitOps integration and best practices.

## Overview

This scaffold provides a standardized project structure for managing AWS infrastructure using Terragrunt, with built-in support for:
- Multi-environment deployments
- Remote state management with S3 and DynamoDB
- Code quality tools (TFLint, pre-commit hooks)
- GitOps workflows
- Modular architecture

## Project Structure

```
#{project_name}#/
├── .thothcf.toml              # Template configuration
├── .gitignore                 # Git ignore rules
├── .tflint.hcl               # TFLint configuration
├── .pre-commit-config.yaml   # Pre-commit hooks
├── root.hcl                  # Root Terragrunt configuration
├── common/
│   ├── common.hcl            # Common variables and provider config
│   └── variables.tf          # Shared variable definitions
├── stacks/
│   └── compute/
│       └── EC2/
│           └── ALB_Main/     # Example stack
└── docs/                     # Documentation and diagrams
```

## Quick Start

### Prerequisites

- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.45.0
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://#{cloud_provider}#.amazon.com/cli/) configured
- [TFLint](https://github.com/terraform-linters/tflint) (optional)
- [Pre-commit](https://pre-commit.com/) (optional)

### Configuration

1. **Update Template Parameters** in `.thothcf.toml`:
```toml
[project_properties]
project = "your-project-name"
environment = "dev"
backend_bucket = "your-project-tfstate"
region = "#{deployment_region}#"
```

2. **Configure Common Variables** in `common/common.hcl`:
```hcl
locals {
  project           = "your-project"
  deployment_region = "#{deployment_region}#"
  backend_bucket_name = "your-project-tfstate"
}
```

### Deployment

```bash
# Initialize and plan
cd stacks/compute/EC2/ALB_Main
terragrunt plan

# Apply changes
terragrunt apply

# Destroy (when needed)
terragrunt destroy
```

## Configuration Files

### `.thothcf.toml`
Template configuration with validation rules for:
- Project naming conventions
- AWS region validation
- S3 bucket naming compliance
- Environment restrictions (dev|qa|stg|test|prod)

### `root.hcl`
Root Terragrunt configuration providing:
- Remote state configuration
- Common variable injection
- Terraform initialization arguments

### `common/common.hcl`
Shared configuration including:
- AWS provider setup with workspace-based profiles
- Default tags for resource management
- Backend configuration for state management

## Features

### Remote State Management
- **S3 Backend**: Centralized state storage
- **DynamoDB Locking**: Prevents concurrent modifications
- **Encryption**: State files encrypted at rest
- **Workspace Support**: Multi-environment state isolation

### Code Quality
- **TFLint**: AWS and Terraform rule validation
- **Pre-commit Hooks**: Automated formatting and validation
- **Git Hooks**: Terragrunt HCL formatting, Terraform validation

### Multi-Environment Support
Workspace-based configuration for:
- `dev`: Development environment
- `qa`: Quality assurance
- `stg`: Staging environment
- `prod`: Production environment

## Template Parameters

| Parameter | Description | Example | Validation |
|-----------|-------------|---------|------------|
| `project_name` | Project identifier | `my-app` | `\b[a-zA-Z]+\b` |
| `deployment_region` | AWS deployment region | `#{deployment_region}#` | `^[a-z]{2}-[a-z]{4,10}-\d$` |
| `backend_bucket` | S3 bucket for state | `my-app-tfstate` | S3 naming rules |
| `environment` | Target environment | `dev` | `(dev\|qa\|stg\|test\|prod)` |
| `cloud_provider` | Cloud provider | `#{cloud_provider}#` | `(#{cloud_provider}#\|azure\|oci\|gcp)` |

## Best Practices

### Directory Structure
- **Stacks**: Organize by service type (compute, network, storage)
- **Modules**: Reusable Terraform modules
- **Environments**: Use Terraform workspaces, not directories

### Naming Conventions
- **Resources**: `{project}-{environment}-{resource-type}`
- **S3 Buckets**: `{project}-{purpose}` (e.g., `myapp-tfstate`)
- **DynamoDB**: `{purpose}-{project}` (e.g., `#{backend_dynamodb}#`)

### Security
- **State Encryption**: Always enabled
- **Access Control**: Use IAM roles and policies
- **Secrets**: Never commit sensitive data
- **Validation**: Use TFLint and pre-commit hooks

## Development Workflow

1. **Create Feature Branch**
```bash
git checkout -b feature/new-infrastructure
```

2. **Make Changes**
```bash
# Edit Terragrunt files
terragrunt plan
```

3. **Validate**
```bash
# Run pre-commit hooks
pre-commit run --all-files

# Run TFLint
tflint --recursive
```

4. **Test**
```bash
# Apply in dev environment
terragrunt apply
```

5. **Submit PR**
```bash
git commit -m "feat: add new infrastructure component"
git push origin feature/new-infrastructure
```

## Troubleshooting

### Common Issues

**State Lock Errors**
```bash
# Force unlock (use carefully)
terragrunt force-unlock LOCK_ID
```

**Backend Initialization**
```bash
# Reconfigure backend
terragrunt init -reconfigure
```

**Module Updates**
```bash
# Update modules
terragrunt init -upgrade
```

### Debugging
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TERRAGRUNT_LOG_LEVEL=debug

terragrunt plan
```

## Contributing

1. Follow the established directory structure
2. Use pre-commit hooks for code quality
3. Update documentation for new features
4. Test changes in dev environment first
5. Follow semantic commit conventions

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Amazon Q Custom Agent

This project includes a custom Amazon Q agent configuration (`agent.json`) optimized for:
- Terragrunt and Terraform operations
- AWS service management
- GitOps workflows
- Infrastructure as Code best practices

The agent provides pre-approved access to:
- File operations for IaC files
- AWS services (S3, DynamoDB, IAM, EC2, VPC)
- Git operations for version control
- Terragrunt/Terraform commands

## Support

For issues and questions:
- Check the troubleshooting section
- Review Terragrunt documentation
- Open an issue in the project repository# Modified for testing
