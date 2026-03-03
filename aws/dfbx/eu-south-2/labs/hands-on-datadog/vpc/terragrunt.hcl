locals {
  # Load configuration from parent folders
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  lab_vars = read_terragrunt_config(find_in_parent_folders("lab.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  lab_name = local.lab_vars.locals.lab_name
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/vpc/vpc.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

inputs = {
  name = "vpc-${local.lab_name}-${local.region_vars.locals.aws_region}"
  cidr = local.lab_vars.locals.vpc_cidr

  azs             = ["${local.region_vars.locals.aws_region}a", "${local.region_vars.locals.aws_region}b"]
  private_subnets = [cidrsubnet(local.lab_vars.locals.vpc_cidr, 8, 1), cidrsubnet(local.lab_vars.locals.vpc_cidr, 8, 2)]
  public_subnets  = [cidrsubnet(local.lab_vars.locals.vpc_cidr, 8, 101), cidrsubnet(local.lab_vars.locals.vpc_cidr, 8, 102)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.env_vars.locals.tags,
    {
      lab-name = local.lab_name
    }
  )
}