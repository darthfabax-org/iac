locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  base_source_url  = "https://github.com/adamwshero/terraform-aws-api-gateway-vpc-link"
}

inputs = {}