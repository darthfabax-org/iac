locals {
  # Read environment configuration from env.hcl, which is located in the parent folders. This allows us to access environment-specific variables and tags defined in env.hcl.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

include "root" {
  # We include the root configuration to inherit the provider and remote state configuration, as well as any variables defined there.
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/s3/s3.hcl"

  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

terraform {
  # The source for this module is defined in the included envcommon configuration, which allows us to reuse the same module source across multiple resources and environments.
  source = "${include.envcommon.locals.base_source_url}"
}

inputs = {
  bucket = "dfbx-example-bucket-${local.region_vars.locals.aws_region}"

  tags = merge(
    local.env_vars.locals.tags,
    {
      name = "dfbx-example-bucket-${local.region_vars.locals.aws_region}"
    }
  )
}
