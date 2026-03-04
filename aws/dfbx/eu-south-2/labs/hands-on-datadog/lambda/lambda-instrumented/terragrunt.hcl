# aws/dfbx/eu-south-2/labs/hands-on-datadog/lambda/lambda-instrumented/terragrunt.hcl

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
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/lambda/lambda.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    private_subnets           = ["subnet-00000000000000000"]
    default_security_group_id = "sg-00000000000000000"
  }
}

inputs = {
  function_name = "${local.lab_vars.locals.lab_name}-instrumented-${local.region_vars.locals.aws_region}"
  description   = "Lambda de laboratorio instrumentada con DataDog Layer"
  memory_size   = 256
  timeout       = 30

  # Handler envuelto: DataDog intercepta la invocación antes de llamar a tu handler
  # Patrón wrapper: DD Layer → tu_modulo.tu_funcion
  handler = "datadog_lambda.handler.handler"
  runtime = "python3.12"

  # Código inline para el laboratorio — en prod sería un S3 artifact
  source_path = ["${get_terragrunt_dir()}/src"]

  # ── DATADOG LAYER ──────────────────────────────────────────────────────────
  # ARN del Layer oficial de DataDog para Python 3.12 en eu-south-2
  # Versiones: https://github.com/DataDog/datadog-lambda-python/releases
  layers = [
    "arn:aws:lambda:eu-south-2:464622532012:layer:Datadog-Python312:97",
    # DD Extension: envía métricas y trazas directamente sin pasar por CloudWatch
    # Ventaja: latencia menor y más métricas custom disponibles
    "arn:aws:lambda:eu-south-2:464622532012:layer:Datadog-Extension:59"
  ]

  # ── VARIABLES DE ENTORNO PARA DD ───────────────────────────────────────────
  environment_variables = {
    # Apunta al handler real de tu función (DD Layer hace de wrapper)
    DD_LAMBDA_HANDLER = "app.handler"

    DD_SITE                    = "datadoghq.eu"
    DD_ENV                     = "labs"
    DD_SERVICE                 = "dd-lab-lambda"
    DD_VERSION                 = "1.0.0"
    DD_TRACE_ENABLED           = "true"
    DD_LOG_LEVEL               = "DEBUG"
    DD_SERVERLESS_LOGS_ENABLED = "true"

    # Lee la API Key desde SSM en runtime (más seguro que env var directa)
    DD_API_KEY_SECRET_ARN = "arn:aws:ssm:${local.region_vars.locals.aws_region}:${local.account_vars.locals.aws_account_id}:parameter/labs/datadog/DD_API_KEY"

    # Captura el payload de request/response para debugging (DESACTIVAR en prod — expone PII)
    DD_CAPTURE_LAMBDA_PAYLOAD = "false"
  }

  attach_network_policy = true

  # Permisos para leer la API Key de SSM
  attach_policy_statements = true
  policy_statements = {
    ssm_read = {
      effect    = "Allow"
      actions   = ["ssm:GetParameter"]
      resources = ["arn:aws:ssm:${local.region_vars.locals.aws_region}:743199288519:parameter/labs/datadog/DD_API_KEY"]
    }
    kms_decrypt = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = ["*"] # En prod: ARN específico de la KMS key de SSM
    }
  }

  vpc_subnet_ids         = dependency.vpc.outputs.private_subnets
  vpc_security_group_ids = [dependency.vpc.outputs.default_security_group_id]

  tags = merge(
    local.env_vars.locals.tags,
    {
      lab-name  = local.lab_vars.locals.lab_name
      dd-traced = "true"
    }
  )
}