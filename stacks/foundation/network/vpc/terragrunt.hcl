include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_WORKSPACE", "dev")
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.0.0"
}

inputs = {
  name = "${local.common_vars.locals.project}-${local.environment}-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["${local.common_vars.locals.deployment_region}a", "${local.common_vars.locals.deployment_region}b", "${local.common_vars.locals.deployment_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = merge(
    local.common_vars.locals.tags,
    {
      Name        = "${local.common_vars.locals.project}-${local.environment}-vpc"
      Layer       = "foundation"
      Domain      = "network"
      Component   = "vpc"
      Environment = local.environment
    }
  )
}