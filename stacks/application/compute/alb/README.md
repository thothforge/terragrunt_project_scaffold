# Application Load Balancer Stack

## Purpose
Creates an Application Load Balancer for routing traffic to application services.

## Dependencies
- Foundation Network VPC
- Foundation IAM Roles

## Resources
- Application Load Balancer
- Target Groups
- Listener Rules
- Security Groups

## Usage
```bash
terragrunt plan
terragrunt apply
```