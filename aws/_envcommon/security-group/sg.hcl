locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  base_source_url  = "https://github.com/terraform-aws-modules/terraform-aws-security-group"
}

inputs = {}