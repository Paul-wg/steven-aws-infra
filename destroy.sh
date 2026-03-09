#!/bin/bash
# Usage: ./destroy.sh dev   or   ./destroy.sh prod
ENV="${1:-dev}"
TFVARS="envs/${ENV}.tfvars"

if [ ! -f "$TFVARS" ]; then
  echo "ERROR: $TFVARS not found. Usage: ./destroy.sh dev|prod"
  exit 1
fi

echo "=========================================="
echo "Environment: $ENV"
echo "Var file:    $TFVARS"
echo "=========================================="

# Select workspace
terraform workspace select "$ENV" 2>/dev/null || { echo "ERROR: Workspace '$ENV' not found"; exit 1; }

echo "Removing S3 from state and destroying other resources..."
terraform state rm module.s3.aws_s3_bucket.main 2>/dev/null
terraform state rm module.s3.aws_s3_bucket_public_access_block.main 2>/dev/null
terraform state rm module.s3.aws_s3_bucket_versioning.main 2>/dev/null
terraform state rm module.s3.aws_s3_bucket_server_side_encryption_configuration.main 2>/dev/null
terraform state rm module.s3.aws_s3_object.init_script 2>/dev/null
terraform state rm module.s3.null_resource.destroy_warning 2>/dev/null

shift 2>/dev/null
terraform destroy -var-file="$TFVARS" "$@"
