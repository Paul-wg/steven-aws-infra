#!/bin/bash
echo "Importing S3 bucket if exists..."
terraform import module.s3.aws_s3_bucket.main ai-foundry-artifacts-apse4 2>/dev/null
echo ""
echo "Running terraform apply..."
terraform apply "$@"
