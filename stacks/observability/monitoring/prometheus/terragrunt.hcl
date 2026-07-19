include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  environment = get_env("TF_VAR_ENVIRONMENT", "dev")
}

# Module source and inputs are injected by terragrunt.stack.hcl autoinclude
# Add stack-specific overrides here
