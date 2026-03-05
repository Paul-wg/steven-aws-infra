# AWS Infrastructure - Terraform

## Structure
```
aws-infra/
├── main.tf              # Root module configuration
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Centralized parameters (VPC, subnet, etc.)
├── outputs.tf           # Root outputs
├── check_bucket.bat     # S3 bucket pre-check script
├── scripts/             # Helper scripts
│   ├── connect-ai-host.bat  # Windows SSM connection script
│   └── connect-ai-host.sh   # Linux/macOS SSM connection script
└── modules/
    ├── ec2/             # EC2 module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3/              # S3 module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── eip/             # Elastic IP module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites
- Terraform >= 1.0
- AWS CLI configured with profile `ai-steven`
- Valid VPC ID and Subnet ID

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

## Setup
1. Update `terraform.tfvars` with your actual VPC ID and Subnet ID
2. (Optional) Run bucket check: `check_bucket.bat ai-foundry-artifacts-apse4 ai-steven`
3. Initialize Terraform:
   ```bash
   terraform init
   ```
4. If bucket exists in your account, import it:
   ```bash
   terraform import module.s3.aws_s3_bucket.main ai-foundry-artifacts-apse4
   ```
5. Review the plan:
   ```bash
   terraform plan
   ```
6. Apply the configuration:
   ```bash
   terraform apply
   ```

## Current Resources
- **EC2 Instance**: t3.micro with 30GB GP3 storage, Amazon Linux 2023
  - Docker pre-installed via user_data
  - AWS CLI v2, tree, htop, git installed
  - IAM role with ECR, S3, and SSM access
- **Security Group**: HTTP (port 80) ingress + full egress
- **S3 Bucket**: Private bucket with versioning and encryption
  - Contains docker-server-init.sh in initialfiles/ folder
- **IAM Role**: EC2 instance role with S3, ECR, and SSM access
- **Elastic IP**: Static public IP for external access

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

## Future Modules
- RDS/Aurora PostgreSQL (to be added)
