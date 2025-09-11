include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

dependencies {
  paths = [
    "../../../foundation/network/vpc",
    "../../../foundation/iam/roles"
  ]
}

inputs = {
  load_balancer_name = "app-alb"
  internal = false
  load_balancer_type = "application"
  enable_deletion_protection = false
}