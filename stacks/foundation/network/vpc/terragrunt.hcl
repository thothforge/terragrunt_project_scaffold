include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}