
plugin "#{cloud_provider}#" {
    enabled = true
    version = "0.21.1"
    source  = "github.com/terraform-linters/tflint-ruleset-#{cloud_provider}#"
}
config {
  module = true
}

plugin "terraform" {
    enabled = true
    version = "0.2.2"
    source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}
