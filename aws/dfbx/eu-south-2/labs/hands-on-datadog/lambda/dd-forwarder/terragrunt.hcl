# aws/dfbx/eu-south-2/labs/hands-on-datadog/lambda/dd-forwarder/terragrunt.hcl

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  lab_vars     = read_terragrunt_config(find_in_parent_folders("lab.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# El Forwarder no tiene módulo en _envcommon porque es específico de DataDog.
# Usamos CloudFormation Stack via Terraform (así lo distribuye DataDog oficialmente).
terraform {
  source = "github.com/DataDog/datadog-serverless-functions//aws/logs_monitoring?ref=v3.120.0"
}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    private_subnets           = ["subnet-00000000000000000"]
    default_security_group_id = "sg-00000000000000000"
    vpc_id                    = "vpc-00000000000000000"
  }
}

inputs = {
  # DataDog destination
  dd_site = "datadoghq.eu"

  # API Key from SSM
  dd_api_key_secret_arn = "arn:aws:ssm:${local.region_vars.locals.aws_region}:${local.account_vars.locals.account_id}:parameter/labs/datadog/DD_API_KEY"

  # The Forwarder is deployed in the private VPC for security
  subnet_ids         = dependency.vpc.outputs.private_subnets
  security_group_ids = [dependency.vpc.outputs.default_security_group_id]

  # DataDog tags to identify the Forwarder
  dd_tags = "env:labs,team:platform,lab:hands-on-datadog"

  # Enable Enhanced Lambda Metrics (extra metrics at no additional cost in free tier)
  dd_enhanced_metrics = true

  tags = merge(
    local.env_vars.locals.tags,
    {
      role = "dd-forwarder"
    }
  )
}
