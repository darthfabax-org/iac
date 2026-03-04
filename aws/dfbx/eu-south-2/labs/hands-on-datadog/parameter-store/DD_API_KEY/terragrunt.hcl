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
  # El módulo v2.0+ usa estas variables directamente para UN parámetro
  # Si necesitas muchos, se suele usar un for_each en el wrapper o llamar al módulo varias veces.
  
  name           = "/labs/datadog/DD_API_KEY"
  value          = "PLACEHOLDER_REPLACE_MANUALLY_IN_CONSOLE"
  type           = "SecureString"
  description    = "DataDog API Key for labs environment"
  secure_type    = true # Importante para SecureString en la nueva versión
  
  tags = merge(
    local.env_vars.locals.tags,
    {
      role = "parameter-store"
    }
  )
}