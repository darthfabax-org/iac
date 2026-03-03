locals {
  environment  = "labs"
  account_name = "dfbx"

  tags = {
    owner       = "${local.account_name}"
    environment = "${local.environment}"
    repository  = "https://github.com/darthfabax-org/iac"
    created-by  = "github-actions"
    ttl         = "7d"
    is-lab      = "true"
  }
}