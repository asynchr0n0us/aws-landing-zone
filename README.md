# AWS Landing Zone — Terraform

AWS Landing Zone with security baseline and networking.

# Architecture

```
AWS
- Management Account
- Security Account      (CloudTrail, GuardDuty, Config, Security Hub)
- Develop Account
- Staging Account
- Production Account
    VPC (multi-AZ)
    Public Subnets   (ALB, NAT Gateway)
    Private Subnets  (ECS/EKS workloads)
    Data Subnets     (RDS, databases)
```

# Features

- **AWS Organizations** with SCPs (Service Control Policies)
- **Multi-account VPC** with private/public/data subnets, NAT Gateway
- **IAM** least-privilege roles and permission boundaries per account
- **Security baseline**: CloudTrail (multi-region), AWS Config, GuardDuty, Security Hub
- **S3 remote backend** with DynamoDB state locking and encryption
- **Pre-commit**: tflint, tfsec, checkov, terraform fmt/validate

# Prerequisites

- Terraform >= 1.6
- AWS CLI configured with management account credentials
- tflint
- trivy
- checkov
- `pre-commit` installed locally

# tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# trivy
sudo apt install wget apt-transport-https gnupg -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -

echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update && sudo apt install trivy -y

# checkov
pip install checkov --break-system-packages

# pre-commit install
python3 -m venv

source /path/to/venv/bin/activate

pip install pre-commit

cd /into/the/project/dir

pre-commit install

# Usage

```bash
# 1. Bootstrap remote state backend
cd bootstrap/
cp terraform.tfvars.template terraform.tfvars
terraform init
terraform plan
terraform apply

# 2. Deploy networking
cd ../networking/
terraform init
terraform plan
terraform apply

# 3. Deploy security baseline
cd ../security/
terraform init
terraform plan
terraform apply
```

# Security Controls

- All S3 buckets: versioning enabled, public access blocked, SSE-S3
- CloudTrail: multi-region, log file validation, S3 access logging
- GuardDuty: enabled in all regions
- Config: all resources recorded with compliance rules
- IAM: password policy, MFA enforced, no root access keys
- SCPs: deny disabling CloudTrail, deny leaving Org, restrict regions  **TBD**


# Estimated Monthly Cost

| Resource            | Est. Cost |
|---------------------|-----------|
| NAT Gateway (x2)    | ~$65      |
| CloudTrail          | ~$2       |
| GuardDuty           | ~$4       |
| Config              | ~$5       |
| Security Hub        | ~$0       |
| **Total**           | **~$76** |
