# 🏗️ Full-Stack Web Infrastructure Deployment with Terraform & CloudFormation

> Automated, production-ready AWS infrastructure using two industry-leading IaC frameworks — deployed with a **single command**, zero manual configuration.

[![Terraform](https://img.shields.io/badge/Terraform-HCL-7B42BC?logo=terraform)](https://www.terraform.io/)
[![CloudFormation](https://img.shields.io/badge/AWS-CloudFormation-FF9900?logo=amazon-aws)](https://aws.amazon.com/cloudformation/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-CodePipeline-232F3E?logo=amazon-aws)](https://aws.amazon.com/codepipeline/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Tech Stack](#tech-stack)
- [Project 1 — Terraform Deployment](#project-1--terraform-deployment)
- [Project 2 — CloudFormation CI/CD Pipeline](#project-2--cloudformation-cicd-pipeline)
- [Infrastructure Parity](#infrastructure-parity)
- [IaC Best Practices Applied](#iac-best-practices-applied)
- [Outputs](#outputs)

---

## Project Overview

This repository demonstrates **Infrastructure as Code (IaC)** mastery by implementing identical, production-ready AWS web infrastructure using **two different frameworks** — Terraform and AWS CloudFormation — across two concurrent projects.

Both solutions provision the complete environment from scratch and deploy a **React + Vite** web application through a fully automated CI/CD pipeline — replacing every manual AWS console step with a single command.

### Why Two Frameworks?

| | Terraform | CloudFormation |
|---|---|---|
| Language | HCL (HashiCorp Config Language) | YAML / JSON |
| Provider | Multi-cloud | AWS Native |
| State Management | `terraform.tfstate` | CloudFormation Stacks |
| Deploy Command | `terraform apply` | `aws cloudformation create-stack` |
| Modularity | Reusable modules | Nested stacks |
| Best For | Multi-cloud, flexibility | Deep AWS integration |

---

## Architecture

```
GitHub Repository
       │
       │  CodeStar Connection (push trigger)
       ▼
┌──────────────────────────────────────────────────┐
│               AWS CodePipeline                   │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌────────────────┐ │
│  │  Source  │→ │  Build   │→ │    Deploy      │ │
│  │ (GitHub) │  │(CodeBuild│  │ (CodeDeploy)   │ │
│  └──────────┘  └──────────┘  └────────────────┘ │
└──────────────────────────────────────────────────┘
       │                  │               │
       │            S3 Artifacts    EC2 Instance
       │              Bucket        (Nginx + App)
       │
       ▼
┌──────────────────────────────────────┐
│            AWS VPC (10.0.0.0/16)     │
│                                      │
│  ┌──────────────────────────────┐    │
│  │      Public Subnet           │    │
│  │      (10.0.1.0/24)           │    │
│  │                              │    │
│  │  ┌──────────────────────┐   │    │
│  │  │    EC2 (t2.micro)    │   │    │
│  │  │  - Nginx Web Server  │   │    │
│  │  │  - CodeDeploy Agent  │   │    │
│  │  │  - CloudWatch Agent  │   │    │
│  │  └──────────────────────┘   │    │
│  └──────────────────────────────┘    │
│                                      │
│  Security Group: HTTP/HTTPS only     │
│  IAM Role: Least-privilege access    │
└──────────────────────────────────────┘
```

---

## Repository Structure

```
IaC/
├── Terraform/                    # Project 1 — Terraform
│   ├── main.tf                   # Core resource definitions
│   ├── variables.tf              # Input variable declarations
│   ├── outputs.tf                # Output values
│   ├── provider.tf               # AWS provider configuration
│   └── modules/                  # Reusable module architecture
│       ├── vpc/                  # VPC, subnets, routing
│       ├── ec2/                  # EC2, security groups
│       └── loadbalancer/         # Load balancer config
│
├── CloudFormation-CICD.yaml      # Project 2 — Full CI/CD stack
└── README.md
```

---

## Tech Stack

**Infrastructure:** AWS VPC · EC2 · S3 · IAM · Security Groups · Internet Gateway

**CI/CD:** AWS CodePipeline · CodeBuild · CodeDeploy · CodeStar Connections

**IaC Frameworks:** Terraform (HCL) · AWS CloudFormation (YAML)

**Web Server:** Nginx · Amazon Linux 2023

**Monitoring:** CloudWatch Logs · CloudWatch Alarms

**Application:** React · Vite · Node.js

---

## Project 1 — Terraform Deployment

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed (`>= 1.0`)
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create VPC, EC2, IAM resources

### Setup & Deploy

**Step 1 — Clone the repository**

```bash
git clone https://github.com/PranavGediya/IaC.git
cd IaC/Terraform
```

**Step 2 — Initialize Terraform**

```bash
terraform init
```

This downloads the AWS provider and initializes the state backend.

**Step 3 — Review the plan**

```bash
terraform plan
```

Review all resources that will be created before applying.

**Step 4 — Configure variables**

Create a `terraform.tfvars` file:

```hcl
project_name    = "my-web-app"
aws_region      = "us-west-2"
instance_type   = "t2.micro"
vpc_cidr        = "10.0.0.0/16"
public_subnet   = "10.0.1.0/24"
```

**Step 5 — Deploy infrastructure**

```bash
terraform apply
```

Type `yes` when prompted. All resources will be provisioned automatically.

**Step 6 — Get outputs**

```bash
terraform output
```

This shows the EC2 public IP, VPC ID, load balancer DNS, and other configured outputs.

### Teardown

```bash
terraform destroy
```

Destroys all provisioned resources cleanly.

---

## Project 2 — CloudFormation CI/CD Pipeline

This template provisions a **complete CI/CD pipeline** for a React + Vite app — from GitHub source to live deployment on EC2 — all in a single stack.

### What Gets Deployed

| Resource | Details |
|---|---|
| **VPC** | `10.0.0.0/16` with public subnet and internet gateway |
| **EC2 Instance** | Amazon Linux 2023, Nginx, CodeDeploy agent, CloudWatch agent |
| **S3 Bucket** | Encrypted artifact store with versioning and lifecycle rules |
| **IAM Roles** | Least-privilege roles for CodePipeline, CodeBuild, CodeDeploy, EC2 |
| **CodePipeline** | 3-stage pipeline: Source → Build → Deploy |
| **CodeBuild** | Installs dependencies, builds React app, outputs artifacts |
| **CodeDeploy** | Deploys build artifacts to EC2 with auto-rollback on failure |
| **CloudWatch** | Log groups (14-day retention) and pipeline failure alarms |

### Prerequisites

- AWS CLI configured
- An existing **GitHub CodeStar Connection ARN** (for source integration)
- A React + Vite app repository on GitHub with an `appspec.yml` and `scripts/` folder

### Parameters

| Parameter | Description | Default |
|---|---|---|
| `ProjectName` | Name prefix for all resources | `react-vite-app` |
| `GitHubOwner` | GitHub username or org | — |
| `GitHubRepo` | Repository name | — |
| `GitHubBranch` | Branch to track | `main` |
| `GitHubConnectionArn` | CodeStar connection ARN | — |
| `EC2InstanceType` | Instance size | `t2.micro` |
| `NodeJSVersion` | Node.js version for build | `20` |

### Deploy via AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name react-vite-cicd \
  --template-body file://CloudFormation-CICD.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=my-app \
    ParameterKey=GitHubOwner,ParameterValue=YOUR_GITHUB_USERNAME \
    ParameterKey=GitHubRepo,ParameterValue=YOUR_REPO_NAME \
    ParameterKey=GitHubBranch,ParameterValue=main \
    ParameterKey=GitHubConnectionArn,ParameterValue=arn:aws:codeconnections:... \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2
```

> ⚠️ `--capabilities CAPABILITY_NAMED_IAM` is required because the template creates named IAM roles.

### Monitor Deployment

```bash
# Watch stack creation progress
aws cloudformation describe-stack-events \
  --stack-name react-vite-cicd \
  --query 'StackEvents[*].[LogicalResourceId,ResourceStatus]' \
  --output table

# Check stack status
aws cloudformation describe-stacks \
  --stack-name react-vite-cicd \
  --query 'Stacks[0].StackStatus'
```

### Deploy via AWS Console

1. Go to **AWS CloudFormation → Stacks → Create Stack**
2. Select **"Upload a template file"**
3. Upload `CloudFormation-CICD.yaml`
4. Fill in the parameters and click **Next**
5. Check **"I acknowledge that AWS CloudFormation might create IAM resources with custom names"**
6. Click **Create Stack**

### Required App Files

Your GitHub repository must include these files for CodeDeploy to work:

**`appspec.yml`** (in root of repo):
```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/html
hooks:
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 300
      runas: root
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 300
      runas: root
```

**`scripts/after_install.sh`**:
```bash
#!/bin/bash
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html
```

**`scripts/start_server.sh`**:
```bash
#!/bin/bash
systemctl restart nginx
```

### Stack Teardown

```bash
aws cloudformation delete-stack --stack-name react-vite-cicd
```

> ⚠️ Empty the S3 artifacts bucket manually before deleting the stack, or the deletion will fail.

---

## Infrastructure Parity

Both projects provision **identical infrastructure** — demonstrating multi-tool proficiency:

| Component | Terraform | CloudFormation |
|---|---|---|
| VPC (`10.0.0.0/16`) | ✅ | ✅ |
| Public Subnet | ✅ | ✅ |
| Internet Gateway | ✅ | ✅ |
| EC2 Instance | ✅ | ✅ |
| Security Groups (HTTP/HTTPS) | ✅ | ✅ |
| IAM Roles (Least Privilege) | ✅ | ✅ |
| Load Balancer | ✅ | ✅ |
| CI/CD Pipeline | ✅ | ✅ |
| CloudWatch Monitoring | ✅ | ✅ |
| Single-command deploy | `terraform apply` | `aws cloudformation create-stack` |

---

## IaC Best Practices Applied

- **Idempotency** — Running the deployment multiple times produces the same result with no duplicate resources
- **Modularization** — Terraform uses reusable modules; CloudFormation uses parameterized templates
- **Version Control** — All infrastructure is code, tracked in Git alongside the application
- **Least Privilege IAM** — Each service role (CodePipeline, CodeBuild, CodeDeploy, EC2) has only the exact permissions it needs
- **Encrypted Storage** — S3 artifact bucket enforces AES-256 server-side encryption
- **Auto-Rollback** — CodeDeploy automatically rolls back on deployment failure
- **Variable Parameterization** — No hardcoded values; all environment-specific configs are parameterized
- **Output Configuration** — Key resource identifiers (EC2 IP, VPC ID, pipeline name) are exported as stack outputs for cross-stack use

---

## Outputs

After deployment, the following values are available:

| Output | Description |
|---|---|
| `WebsiteURL` | Public DNS URL of the deployed application |
| `EC2InstanceId` | EC2 instance identifier |
| `EC2PublicIP` | Public IP address of the web server |
| `CodePipelineName` | Name of the created pipeline |
| `CodeBuildProject` | CodeBuild project name |
| `ArtifactsBucket` | S3 bucket storing build artifacts |
| `VPCId` | VPC resource ID |
| `PublicSubnetId` | Public subnet resource ID |

---

> **Feb 2023 – Apr 2023** · Built as part of cloud infrastructure and DevOps learning  
> 🔗 [View Repository on GitHub](https://github.com/PranavGediya/IaC)
