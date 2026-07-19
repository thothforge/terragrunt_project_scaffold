# Platform Stack — shared services
# Depends on foundation stack outputs

unit "eks" {
  source = "tfr:///terraform-aws-modules/eks/aws?version=20.31.0"
  path   = "containers/eks"

  autoinclude {
    dependency "vpc" {
      config_path = "../../foundation/network/vpc"
    }
    dependency "iam_roles" {
      config_path = "../../foundation/iam/roles"
    }
    inputs = {
      vpc_id     = dependency.vpc.outputs.vpc_id
      subnet_ids = dependency.vpc.outputs.private_subnets
    }
  }
}

unit "ecr" {
  source = "tfr:///terraform-aws-modules/ecr/aws?version=2.3.0"
  path   = "containers/ecr"
}

unit "rds" {
  source = "tfr:///terraform-aws-modules/rds/aws?version=6.10.0"
  path   = "data/rds"

  autoinclude {
    dependency "vpc" {
      config_path = "../../foundation/network/vpc"
    }
    inputs = {
      subnet_ids = dependency.vpc.outputs.database_subnets
      vpc_security_group_ids = [dependency.vpc.outputs.default_security_group_id]
    }
  }
}

unit "elasticache" {
  source = "tfr:///terraform-aws-modules/elasticache/aws?version=1.4.0"
  path   = "data/elasticache"

  autoinclude {
    dependency "vpc" {
      config_path = "../../foundation/network/vpc"
    }
    inputs = {
      subnet_ids = dependency.vpc.outputs.elasticache_subnets
    }
  }
}
