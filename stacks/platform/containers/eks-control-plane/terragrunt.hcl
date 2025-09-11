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
  cluster_name = "gitops-${local.environment}"
  kubernetes_version = "1.28"
  endpoint_private_access = true
  endpoint_public_access = true
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
}