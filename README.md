# Terragrunt IaC

Deploy IaC with Terragrunt in multiple AWS accounts.

This repository contains the Terraform and Terragrunt configurations for deploying infrastructure in multiple AWS accounts. The repository is organized into different folders based on the AWS account and region.

## Requirements

- Terraform: v1.10.3 or higher
- Terragrunt: v0.69.11 or higher
- Setup IAM identity provider in AWS to allow Github Actions.
- Setup IAM role in AWS to allow Github Actions deploy resources.

## Folder Structure

```bash
aws/
├── _envcommon/           # Reusable modules
├── dfbx/                 # Account
│   ├── account.hcl
│   ├── env.hcl
│   ├── eu-south-2/       # Region
│   │   ├── region.hcl
│   │   └── resources/
│   │       ├── s3/
│   │       ├── vpc/
│   │       └── rds/
├── xbfd/                 # Another Account
│   ├── account.hcl
│   ├── env.hcl
│   ├── us-east-1/ 
│       ├── region.hcl    # Another region
│       └── resources/
└── root.hcl              # Provider config
```

### Environment Configuration

- `aws/dfbx/account.hcl`: This file contains the account-level configuration for the AWS account, including the account name and ID.
- `aws/dfbx/env.hcl`: This file contains the environment-level configuration, including the environment name and tags.
- `aws/dfbx/region.hcl`: This file contains the environment-level region configuration.
- `aws/dfbx/eu-south-2/resources/example/single-module`: This file contains the Terragrunt configuration for deploying an S3 bucket in the eu-south-2 region.

### Modules Configuration

- `aws/_envcommon`: This directory contains reusable modules.
- `aws/_envcommon/s3/s3.hcl`: This file contains the Terragrunt configuration for the S3 module, which can be reused across different environments and regions.
- `aws/dfbx/eu-south-2/resources/examples/single-module/terragrunt.hcl`: This file contains the Terragrunt configuration for deploying an S3 bucket in the eu-south-2 region.

## Usage

To deploy the infrastructure, navigate to the desired resource directory witthin environment and region directory and run the following command:

```bash
# Move to single-module resource example
cd ./aws/dfbx/eu-south-2/resources/examples/single-module

# Init terraform configuration
terragrunt init

# Fix syntax
terragrunt hclfmt

# Validate configuration
terragrunt validate

# Plan deployment
terragrunt plan

# Apply plan
terragrunt apply

# Destroy plan
terragrunt destroy
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.
