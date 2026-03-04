locals {
  # Load configuration from parent folders
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  lab_vars    = read_terragrunt_config(find_in_parent_folders("lab.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  lab_name = local.lab_vars.locals.lab_name
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ec2/ec2.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnets           = ["subnet-00000000000000000"]
    default_security_group_id = "sg-00000000000000000"
  }
}

inputs = {
  name = "node-${local.lab_name}-${local.region_vars.locals.aws_region}"

  instance_type = "t3.micro"

  subnet_id              = dependency.vpc.outputs.private_subnets[0]
  vpc_security_group_ids = [dependency.vpc.outputs.default_security_group_id]

  associate_public_ip_address = false

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for telemetry and SSM access to the lab"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    # Trade-off de Laboratorio: Usamos una política manejada de lectura para no crear un recurso IAM adicional. 
    # En PROD: Crearíamos una política custom estricta solo para el ARN de "/labs/datadog/api-key"
    SSMReadOnlyAccess = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  }

  # Excelencia Operativa: Bootstrapping Idempotente
  # Ejecuta el fetch del secreto en tiempo real durante el arranque de la máquina.
  user_data = <<-EOT
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    
    echo "Starting Datadog agent provisioning..."

    # 1. Retrieve API Key from SSM Parameter Store
    # jq is required to parse the JSON response
    yum install -y jq
    
    DD_API_KEY=$(aws ssm get-parameter \
      --name "/labs/datadog/DD_API_KEY" \
      --with-decryption \
      --region ${local.region_vars.locals.aws_region} \
      --output json | jq -r '.Parameter.Value')

    if [ -z "$DD_API_KEY" ] || [ "$DD_API_KEY" == "null" ]; then
      echo "CRITICAL: Could not retrieve API Key from SSM Parameter Store. Aborting."
      exit 1
    fi

    # 2. Install Datadog agent in a unattended manner
    DD_API_KEY=$DD_API_KEY \
    DD_SITE="datadoghq.eu" \
    DD_LOGS_CONFIG_PROCESS_COLLECT_ALL=true \
    DD_HOST_TAGS="env:labs,role:datadog-agent-test" \
    bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"

    echo "Datadog agent installed successfully."
  EOT

  tags = merge(
    local.env_vars.locals.tags,
    {
      lab-name = local.lab_name
      role     = "datadog-agent-test"
    }
  )
}