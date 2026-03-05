# AWS Infrastructure - Terraform

## Structure
```
aws-infra/
├── main.tf              # Root module configuration
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Centralized parameters
├── outputs.tf           # Root outputs
├── apply.bat/sh         # Terraform apply wrapper
├── destroy.bat/sh       # Terraform destroy wrapper
├── check_bucket.bat     # S3 bucket pre-check script
├── doc/                 # Documentation
│   ├── POC_SETUP.md
│   ├── S3_BUCKET_GUIDE.md
│   ├── S3_SECURITY_VERIFICATION.md
│   ├── SSM_ACCESS_VERIFICATION.md
│   └── DEPENDENCY_VERIFICATION.md
├── scripts/             # Helper scripts
│   ├── connect-ai-host.bat/sh   # SSM connection scripts
│   └── safe-destroy.bat/sh      # Safe destroy with checks
└── modules/
    ├── vpc/             # VPC module
    ├── ec2/             # EC2 module
    ├── rds/             # RDS PostgreSQL module
    ├── s3/              # S3 module
    └── eip/             # Elastic IP module
```

## Prerequisites
- Terraform >= 1.0
- AWS CLI configured with profile `ai-steven`
- Session Manager plugin (for SSM access)

## S3 Bucket Behavior

### Bucket Existence Check
Before running terraform, you can check bucket status:
```bash
check_bucket.bat ai-foundry-artifacts-apse4 ai-steven
```

**Scenarios:**
1. **Bucket doesn't exist**: Terraform will create it
2. **Bucket exists in your account**: Terraform will import and use it (run: `terraform import module.s3.aws_s3_bucket.main ai-foundry-artifacts-apse4`)
3. **Bucket exists in another account**: Terraform will error with "bucket name already taken" - choose a different name

### Bucket Protection
- **lifecycle { prevent_destroy = true }**: Prevents accidental deletion via Terraform
- **terraform destroy**: Will show warning but SKIP bucket deletion, keeping data safe
- To actually delete the bucket, you must:
  1. Remove the `prevent_destroy` lifecycle rule
  2. Run `terraform destroy` again

## Quick Start
1. Update `terraform.tfvars` with your parameters
2. Run apply script:
   ```bash
   apply.bat      # Windows
   ./apply.sh     # Linux/macOS
   ```
3. Connect to instance:
   ```bash
   scripts\connect-ai-host.bat  # Windows
   ./scripts/connect-ai-host.sh # Linux/macOS
   ```

## Current Resources
- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **EC2 Instance**: t3.micro with 30GB GP3 storage, Amazon Linux 2023
  - Docker pre-installed via user_data
  - AWS CLI v2, tree, htop, git installed
  - IAM role with ECR, S3, and SSM access
- **RDS PostgreSQL**: db.t3.micro with 20GB storage
  - Multi-AZ deployment in private subnets
  - Automated backups (7-day retention)
- **Security Groups**: Configured for EC2 (HTTP) and RDS (PostgreSQL)
- **S3 Bucket**: Private bucket with versioning and encryption
- **Elastic IP**: Static public IP for EC2

## POC Deployment Support

This infrastructure is designed to support the Simple POC deployment:

### Initialization Process
1. EC2 launches with user_data script
2. Downloads docker-server-init.sh from S3 bucket
3. Installs Docker, AWS CLI v2, tree, htop, git
4. Configures Docker for ec2-user
5. Elastic IP automatically associated

### EC2 Capabilities
- ✅ Pull Docker images from ECR
- ✅ Access S3 bucket for artifacts
- ✅ SSM Session Manager access (no SSH needed)
- ✅ Run Docker containers on port 80
- ✅ Static public IP for web access

### Accessing the Instance
```bash
# Via SSM Session Manager using tag (no SSH keys needed)
scripts\connect-ai-host.bat  # Windows
./scripts/connect-ai-host.sh  # Linux/macOS

# Or manually with instance ID
aws ssm start-session --target <instance-id> --profile ai-steven

# Check initialization log
sudo cat /var/log/docker-server-init.log

# Test Docker
docker --version
docker ps
```

## Git Workflow

### Repository Setup
This repository excludes Terraform-generated files:
- `terraform.tfstate*` (state files)
- `.terraform/` (providers/modules cache)
- `.terraform.lock.hcl` (lock file)
- Editor temp files (*.swp)

### Initial Push
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

### If Large Files Were Committed
If you accidentally committed Terraform providers:
```bash
# Remove from Git history
git filter-branch --force --index-filter \
  "git rm -rf --cached --ignore-unmatch .terraform/ terraform.tfstate*" \
  --prune-empty --tag-name-filter cat -- --all

# Force push cleaned history
git push origin main --force
```
