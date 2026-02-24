locals {
  # Read environment configuration from env.hcl, which is located in the parent folders. This allows us to access environment-specific variables and tags defined in env.hcl.
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Expose the base source URL so different versions of the module can be deployed in different environments. This will
  # be used to construct the source URL in the child terragrunt configurations.
  base_source_url = "https://github.com/terraform-aws-modules/terraform-aws-s3-bucket"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # Required settings for Terraform backend
  versioning = {
    enabled = true
  }

  # Encryption is mandatory for state files
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Enable object locking for additional security
  object_lock_configuration = {
    object_lock_enabled = "Enabled"
  }

  # Lifecycle rules
  lifecycle_rule = [
    {
      id      = "state"
      enabled = true

      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]

}
