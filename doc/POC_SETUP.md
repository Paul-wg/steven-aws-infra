# POC Infrastructure Setup Guide

## Overview
This infrastructure supports the Simple POC Deployment as described in POC_SIMPLE_DEPLOYMENT.md

## What's Included

### 1. EC2 Instance (Docker Host)
- **Type**: t3.micro
- **OS**: Amazon Linux 2023
- **Storage**: 30GB GP3 encrypted
- **Pre-installed Software**:
  - Docker (latest)
  - AWS CLI v2
  - tree, htop, git

### 2. IAM Role & Permissions
EC2 instance has permissions for:
- ✅ ECR: Pull Docker images
- ✅ S3: Upload/download/delete files
- ✅ SSM: Session Manager access (no SSH keys!)

### 3. Security Group
- **Ingress**: Port 80 (HTTP) from 0.0.0.0/0
- **Egress**: All traffic

### 4. Elastic IP
- Static public IP address
- Automatically associated with EC2
- Use this IP for GitHub Actions deployment

### 5. S3 Bucket
- **Name**: ai-foundry-artifacts-apse4
- **Contains**: docker-server-init.sh in initialfiles/ folder
- **Protected**: Won't be deleted on terraform destroy

## Initialization Flow

```
EC2 Launch
    │
    ├─> User Data Script Runs
    │   │
    │   ├─> Download docker-server-init.sh from S3
    │   │
    │   └─> Execute docker-server-init.sh
    │       │
    │       ├─> Install Docker
    │       ├─> Install AWS CLI v2
    │       ├─> Install tree, htop, git
    │       └─> Configure Docker for ec2-user
    │
    └─> Elastic IP Associated
```

## Deployment Steps

### 1. Initialize Terraform
```bash
cd aws-infra
terraform init
```

### 2. Review Plan
```bash
terraform plan
```

### 3. Apply Configuration
```bash
terraform apply
```

### 4. Get Outputs
```bash
terraform output
```

**Important Outputs:**
- `eip_public_ip` - Use this for GitHub Actions
- `eip_allocation_id` - Use this for EIP association in CI/CD
- `ec2_instance_id` - Use this for SSM and EIP association

## Post-Deployment

### Verify EC2 Initialization
```bash
# Connect via SSM
aws ssm start-session --target <instance-id> --profile ai-steven

# Check initialization log
sudo cat /var/log/docker-server-init.log

# Verify Docker
docker --version
docker ps

# Verify AWS CLI
aws --version

# Test ECR access
aws ecr get-login-password --region ap-southeast-4
```

### Test Web Access
```bash
# From your laptop
curl http://<eip_public_ip>/

# Should return connection refused (no container running yet)
# This is expected - container will be deployed by GitHub Actions
```

## GitHub Actions Configuration

Update your GitHub Actions workflow with these values:

```yaml
env:
  AWS_REGION: ap-southeast-4
  EC2_HOST: <eip_public_ip>          # From terraform output
  EIP_ALLOC: <eip_allocation_id>     # From terraform output
  INSTANCE_ID: <ec2_instance_id>     # From terraform output
```

## Updating docker-server-init.sh

If you need to update the initialization script:

1. Edit `modules/ec2/docker-server-init.sh`
2. Run `terraform apply` to upload new version to S3
3. Manually run on EC2:
   ```bash
   aws s3 cp s3://ai-foundry-artifacts-apse4/initialfiles/docker-server-init.sh /tmp/docker-server-init.sh
   chmod +x /tmp/docker-server-init.sh
   sudo /tmp/docker-server-init.sh
   ```

## Troubleshooting

### Issue: EC2 can't pull from ECR
```bash
# Check IAM role
aws sts get-caller-identity

# Test ECR login
aws ecr get-login-password --region ap-southeast-4 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-4.amazonaws.com
```

### Issue: Can't access via SSM
```bash
# Check SSM agent status
sudo systemctl status amazon-ssm-agent

# Restart if needed
sudo systemctl restart amazon-ssm-agent
```

### Issue: Port 80 not accessible
```bash
# Check security group allows port 80
# Check Docker container is running: docker ps
# Check from EC2: curl localhost
```

## Cost Estimate

| Resource | Cost/Month |
|----------|------------|
| EC2 t3.micro | ~$7.50 |
| EIP (associated) | $0 |
| S3 storage | ~$0.10 |
| Data transfer | ~$1 |
| **Total** | **~$9/month** |

## Clean Up

To destroy infrastructure (S3 bucket will be kept):
```bash
terraform destroy
```

To actually delete S3 bucket:
1. Remove `prevent_destroy` from modules/s3/main.tf
2. Run `terraform destroy` again
