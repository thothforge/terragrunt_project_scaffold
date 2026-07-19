# Foundation Stack — core infrastructure
# Terragrunt 1.1: Stack-based composition with autoinclude dependencies

unit "vpc" {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.16.0"
  path   = "network/vpc"
}

unit "iam_roles" {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-role?version=5.48.0"
  path   = "iam/roles"
}

unit "security_groups" {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.2.0"
  path   = "network/security-groups"

  autoinclude {
    dependency "vpc" {
      config_path = unit.vpc.path
    }
    inputs = {
      vpc_id = dependency.vpc.outputs.vpc_id
    }
  }
}
