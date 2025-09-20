include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../../foundation/network/vpc"
  mock_outputs = {
    vpc_id = "vpc-04e3e1e302f8c8f06"
    public_subnets = [
      "subnet-0e4c5aedfc2101502",
      "subnet-0d5061f70b69eda14",
    ]
    private_subnets = [
      "subnet-0e4c5aedfc2101502",
      "subnet-0d5061f70b69eda14",
      "subnet-0d5061f70b69eda15",
    ]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "iam_roles" {
  config_path = "../../../foundation/iam/roles"
  mock_outputs = {
    iam_role_arn = "arn:aws:iam::123456789012:role/mock-eks-service-role"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_WORKSPACE", "dev")
  
  # Environment-specific configuration
  env_config = {
    dev = {
      create = true
      cluster_version = "1.28"
      cluster_endpoint_public_access = true
    }
    prod = {
      create = true
      cluster_version = "1.28"
      cluster_endpoint_public_access = false
    }
  }
  
  workspace_config = lookup(local.env_config, local.environment, local.env_config.dev)
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=21.0.0"
}

inputs = {
  create = local.workspace_config.create
  
  cluster_name    = "${local.common_vars.locals.project}-${local.environment}-eks"
  cluster_version = local.workspace_config.cluster_version
  
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets
  
  cluster_endpoint_public_access = local.workspace_config.cluster_endpoint_public_access
  cluster_endpoint_private_access = true
  
  enable_cluster_creator_admin_permissions = true
  
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  
  tags = merge(
    local.common_vars.locals.tags,
    {
      Name        = "${local.common_vars.locals.project}-${local.environment}-eks"
      Layer       = "platform"
      Domain      = "containers"
      Component   = "eks-control-plane"
      Environment = local.environment
    }
  )
}