#!/bin/bash
# Usage: ./safe-destroy.sh dev   or   ./safe-destroy.sh prod

ENV="${1:-dev}"
TFVARS="../envs/${ENV}.tfvars"

if [ ! -f "$TFVARS" ]; then
  TFVARS="envs/${ENV}.tfvars"
fi

if [ ! -f "$TFVARS" ]; then
  echo "ERROR: envs/${ENV}.tfvars not found. Usage: ./safe-destroy.sh dev|prod"
  exit 1
fi

echo "=========================================="
echo "Safe Terraform Destroy — Environment: $ENV"
echo "=========================================="
echo "This will:"
echo "1. Remove S3 bucket from Terraform state"
echo "2. Destroy all other resources (RDS Aurora, EC2, EIP, IAM, VPC endpoints/SGs)"
echo "   NOTE: Private DB subnets are NOT managed by Terraform — will NOT be destroyed"
echo "3. Keep S3 bucket intact in AWS"
echo "=========================================="
echo

read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Select workspace
terraform workspace select "$ENV" 2>/dev/null || { echo "ERROR: Workspace '$ENV' not found"; exit 1; }

echo
echo "Step 1: Removing S3 resources from Terraform state..."
terraform state rm module.s3.aws_s3_bucket.main 2>/dev/null || echo "  - S3 bucket already removed or doesn't exist"
terraform state rm module.s3.aws_s3_bucket_public_access_block.main 2>/dev/null || echo "  - Public access block already removed"
terraform state rm module.s3.aws_s3_bucket_versioning.main 2>/dev/null || echo "  - Versioning already removed"
terraform state rm module.s3.aws_s3_bucket_server_side_encryption_configuration.main 2>/dev/null || echo "  - Encryption config already removed"
terraform state rm module.s3.aws_s3_object.init_script 2>/dev/null || echo "  - Init script already removed"
terraform state rm module.s3.null_resource.destroy_warning 2>/dev/null || echo "  - Destroy warning already removed"

echo
echo "Step 2: Destroying remaining resources..."
terraform destroy -var-file="$TFVARS"

echo
echo "=========================================="
echo "Destroy complete!"
echo "S3 bucket 'ai-foundry-artifacts-apse4' is preserved in AWS"
echo "=========================================="
