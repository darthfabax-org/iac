# aws/dfbx/eu-south-2/labs/hands-on-datadog/parameter-store/terragrunt.hcl

locals {
  # Load configuration from parent folders
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  lab_vars    = read_terragrunt_config(find_in_parent_folders("lab.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
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
  parameters = {
    "/labs/datadog/DD_API_KEY" = {
      type        = "SecureString"
      description = "DataDog API Key for labs environment"
      value       = "PLACEHOLDER_REPLACE_MANUALLY_IN_CONSOLE"
      overwrite   = false  # Do not overwrite if the parameter already exists
    }

    "/labs/datadog/DD_APP_KEY" = {
      type        = "SecureString"
      description = "DataDog APP Key for labs environment"
      value       = "PLACEHOLDER_REPLACE_MANUALLY_IN_CONSOLE"
      overwrite   = false
    }
  }

  tags = merge(
    local.env_vars.locals.tags,
    {
      role = "parameter-store"
    }
  )
}

