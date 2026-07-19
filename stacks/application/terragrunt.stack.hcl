# Application Stack — application-specific infrastructure

unit "alb" {
  source = "tfr:///terraform-aws-modules/alb/aws?version=9.12.0"
  path   = "compute/alb"

  autoinclude {
    dependency "vpc" {
      config_path = "../../foundation/network/vpc"
    }
    dependency "security_groups" {
      config_path = "../../foundation/network/security-groups"
    }
    inputs = {
      vpc_id          = dependency.vpc.outputs.vpc_id
      subnets         = dependency.vpc.outputs.public_subnets
      security_groups = [dependency.security_groups.outputs.security_group_id]
    }
  }
}

unit "asg" {
  source = "tfr:///terraform-aws-modules/autoscaling/aws?version=8.0.0"
  path   = "compute/asg"

  autoinclude {
    dependency "vpc" {
      config_path = "../../foundation/network/vpc"
    }
    dependency "alb" {
      config_path = unit.alb.path
    }
    inputs = {
      vpc_zone_identifier = dependency.vpc.outputs.private_subnets
      target_group_arns   = dependency.alb.outputs.target_group_arns
    }
  }
}

unit "s3" {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws?version=4.2.0"
  path   = "storage/s3"
}

unit "efs" {
  source = "tfr:///terraform-aws-modules/efs/aws?version=1.6.0"
  path   = "storage/efs"

  autoinclude {
    dependency "vpc" {
      config_path = "../../foundation/network/vpc"
    }
    inputs = {
      vpc_id     = dependency.vpc.outputs.vpc_id
      subnet_ids = dependency.vpc.outputs.private_subnets
    }
  }
}
