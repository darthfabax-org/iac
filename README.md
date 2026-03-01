# 🌍 Terragrunt Multi-Account IaC

Deploy and manage Infrastructure as Code (IaC) at scale across multiple AWS accounts using the power of **Terragrunt** and **Terraform**.

---

## 📋 Overview

This repository centralizes the infrastructure definitions for the entire organization. By leveraging a decoupled architecture, it allows for:

* **DRY (Don't Repeat Yourself)** configurations.
* **Multi-Account/Multi-Region** orchestration from a single source.
* **Consistency** through reusable local modules and environment inheritance.

---

## 🛠 Prerequisites

Before interacting with this repository, ensure you have the following tools and configurations in place:

* **Binaries:**
* **Terraform:** `v1.10.3` or higher.
* **Terragrunt:** `v0.69.11` or higher.

| Secret / Input | Description |
| :--- | :--- |
| `AWS_ACTIONS_ROLE_ARN` | IAM Role ARN for OIDC authentication. |
| `SLACK_WEBHOOK_URL` | (Optional) Webhook URL for sending alerts to Slack channels. |
| `GITHUB_TOKEN` | Automatic token for GitHub API interactions (PRs, Issues). |
| `INFRACOST_API_KEY` | (Optional) API Key for cost estimation in Terragrunt plans. |

---

## 🔄 CI/CD Workflows

This repository follows a decoupled GitHub Actions architecture. Local workflows act as "callers" that invoke centralized, reusable logic from the [darthfabax-org/actions](https://github.com/darthfabax-org/actions) repository.

### 🏗️ Infrastructure Lifecycle

* **Plan (on Pull Request)**: Triggered automatically when a PR includes changes to `.hcl` files (excluding `_envcommon/`). It performs syntax validation, HCL formatting checks, and provides a preview of infrastructure changes.
* **Apply (on Push to Main)**: When changes are merged into `main`, this workflow first runs a validation plan. If changes are detected, it automatically deploys the infrastructure across the affected directories using a parallel matrix strategy.
* **Drift Detection (Scheduled)**: A routine scan runs daily at 08:00 UTC to identify discrepancies between the actual AWS state and the Terraform configuration. If drift is found, it can automatically manage GitHub Issues for remediation.
* **Manual Destroy**: A `workflow_dispatch` (manual) trigger that allows for the controlled teardown of specific resources by providing the target directory as input.

### 🔐 Pipeline Matrix

| Workflow | Trigger | Action Source | Purpose |
| :--- | :--- | :--- | :--- |
| **Terragrunt Plan** | `pull_request` | `./github/workflows/terragrunt-plan.yml` | Validate HCL logic and estimate costs in PRs. |
| **Terragrunt Apply** | `push` (main) | `./github/workflows/terragrunt-apply.yml` | Deploy approved changes to production. |
| **Drift Detection** | `schedule` | `./github/workflows/terragrunt-drift.yml` | 24/7 monitoring of infrastructure integrity. |
| **Terragrunt Destroy** | `manual` | `./github/workflows/terragrunt-destroy.yml` | Safe, manual decommissioning of resources. |

> **Note:** All workflows use `secrets: inherit` to securely pass OIDC AWS credentials, Slack webhooks, and GitHub

---

## 🏗️ Custom Composite Actions

To maintain consistency and reduce code duplication, this repository utilizes **Custom Composite Actions** located in `./github/actions` directory. These actions standardize the environment setup for every job.

### 🔑 Setup AWS Credentials

This action handles the secure authentication process with AWS using OpenID Connect (OIDC).

* **OIDC Authentication**: It exchanges a GitHub token for temporary AWS credentials, removing the need for long-lived IAM keys.
* **Identity Verification**: Includes a built-in step to run `aws sts get-caller-identity`, confirming a successful connection before proceeding with IaC tasks.

### 🛠️ Setup Terraform & Terragrunt

A specialized action to ensure the correct versions of Infrastructure as Code binaries are present in the runner.

* **Version Control**: Installs Terraform (default `1.10.3`) and Terragrunt (default `0.69.11`).
* **Automated Installation**: It automatically fetches the Terragrunt binary from the official Gruntwork releases and configures execution permissions.
* **Tool Verification**: Executes a version check for both tools to "fail-fast" if the installation is not correct.

---

## 📂 Folder Structure

The hierarchy follows a "Location-Based" pattern, making it easy to identify where resources reside:

```bash
aws/
├── _envcommon/           # 📦 Reusable base configurations (The "Source of Truth")
├── dfbx/                 # 🏢 Account: DFBX
│   ├── account.hcl       # Account-level metadata
│   ├── env.hcl           # Environment-level settings (prod/stage)
│   ├── eu-south-2/       # 📍 Region
│   │   ├── region.hcl
│   │   └── resources/    # Specific Cloud Resources
│   │       ├── s3/
│   │       ├── vpc/
│   │       └── rds/
├── xbfd/                 # 🏢 Account: XBFD
│   ├── account.hcl
│   ├── env.hcl
│   └── us-east-1/        # 📍 Region
│       ├── region.hcl
│       └── resources/
└── root.hcl              # ⚙️ Global Provider & Remote State config
```

## ⚖️ License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
