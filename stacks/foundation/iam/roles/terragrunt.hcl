include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
  create_eks_service_role = true
  create_eks_node_role = true
  create_gitops_role = true
  trusted_role_arns = []
}