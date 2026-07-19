# Product Overview

## Terragrunt Project Scaffold

A production-ready Terragrunt 1.1 scaffold for AWS infrastructure at scale, featuring:
- Stack-based composition with `terragrunt.stack.hcl`
- Content Addressable Store (CAS) for source de-duplication
- Multi-environment support via `environments/` directory
- Layered architecture (foundation → platform → application → observability)
- GitOps-ready with pre-commit hooks and ThothCTL integration

## Target Users
- Platform engineering teams
- DevOps/DevSecOps engineers
- Infrastructure teams managing AWS at scale

## Key Principles
- DRY configuration through Terragrunt includes and stacks
- Explicit dependency graphs between infrastructure layers
- Environment isolation via tfvars (not directory duplication)
- Security-first with required tags and validated inputs
