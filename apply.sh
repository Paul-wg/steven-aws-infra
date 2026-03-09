#!/bin/bash
# Usage: ./apply.sh dev   or   ./apply.sh prod
ENV="${1:-dev}"
TFVARS="envs/${ENV}.tfvars"

if [ ! -f "$TFVARS" ]; then
  echo "ERROR: $TFVARS not found. Usage: ./apply.sh dev|prod"
  exit 1
fi

echo "=========================================="
echo "Environment: $ENV"
echo "Var file:    $TFVARS"
echo "=========================================="

# Select or create workspace
terraform workspace select "$ENV" 2>/dev/null || terraform workspace new "$ENV"

# Import shared S3 bucket if not in state
echo "Importing S3 bucket if exists..."
terraform import -var-file="$TFVARS" module.s3.aws_s3_bucket.main ai-foundry-artifacts-apse4 2>/dev/null

echo ""
echo "Running terraform apply..."
shift 2>/dev/null
terraform apply -var-file="$TFVARS" "$@"
