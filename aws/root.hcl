# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform/OpenTofu that provides extra tools for working with multiple modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  environment_suffix = local.environment_vars.locals.environment == "production" ? "" : "${local.environment_vars.locals.environment}"

  # Extract the variables we need for easy access
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.account_id
  aws_region   = local.region_vars.locals.aws_region

  # This accounts can assume role for tf state in shared services.
  trusted_arns = [
    "arn:aws:iam::743199288519:role/dfbx-github-actions-role-iac", # GITHUB ACTIONS
    "arn:aws:iam::743199288519:role/dfbx-admin-role-iac"           # TERRAFORM CLI
  ]
  account_ids = [for arn in local.trusted_arns : split(":", arn)[4]]
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      creator     = "terragrunt"
      state       = "true"
      repository  = "https://github.com/darthfabax-org/iac"
    }
  }

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ${jsonencode(local.account_ids)}
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  
config = {
    encrypt        = true
    bucket         = "dfbx-terraform-state-${local.account_name}-${local.environment_suffix}-${local.aws_region}"
    key            = "${path_relative_to_include()}/tf.tfstate"
    region         = local.aws_region
    dynamodb_table = "dfbx-terraform-state-lock-${local.account_name}-${local.environment_suffix}-${local.aws_region}"

    s3_bucket_tags = {
      name        = "Terraform State Storage"
      creator     = "terragrunt"
      environment = local.environment_vars.locals.environment
      owner       = local.account_vars.locals.account_name
      repository  = "https://github.com/darthfabax-org/iac"
    }

    dynamodb_table_tags = {
      name        = "Terraform Lock Table"
      creator     = "terragrunt"
      environment = local.environment_vars.locals.environment
      owner       = local.account_vars.locals.account_name
      repository  = "https://github.com/darthfabax-org/iac"
    }
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  local.environment_vars.locals,
)
