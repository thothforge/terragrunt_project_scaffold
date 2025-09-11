include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_WORKSPACE", "dev")
}

terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-role?version=6.2.1"
}

inputs = {
  role_name = "${local.common_vars.locals.project}-${local.environment}-eks-service-role"
  
  trusted_role_services = [
    "eks.amazonaws.com",
    "ec2.amazonaws.com"
  ]
  
  role_requires_mfa = false
  
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
  
  tags = merge(
    local.common_vars.locals.tags,
    {
      Name        = "${local.common_vars.locals.project}-${local.environment}-eks-service-role"
      Layer       = "foundation"
      Domain      = "iam"
      Component   = "roles"
      Environment = local.environment
    }
  )
}