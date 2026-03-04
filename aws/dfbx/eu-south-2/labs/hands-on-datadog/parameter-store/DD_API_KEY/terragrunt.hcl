# aws/dfbx/eu-south-2/labs/hands-on-datadog/parameter-store/DD_API_KEY/terragrunt.hcl

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  lab_vars     = read_terragrunt_config(find_in_parent_folders("lab.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/parameter-store/parameter-store.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

inputs = {
  name           = "/labs/datadog/DD_API_KEY"
  value          = "PLACEHOLDER_REPLACE_MANUALLY_IN_CONSOLE"
  type           = "SecureString"
  description    = "DataDog API Key for labs environment"
  secure_type    = true
  
  tags = merge(
    local.env_vars.locals.tags,
    {
      role = "parameter-store"
    }
  )
}
