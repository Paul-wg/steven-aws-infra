#!/bin/bash
echo "Removing S3 from state and destroying other resources..."
terraform state rm module.s3.aws_s3_bucket.main 2>/dev/null
terraform state rm module.s3.aws_s3_bucket_public_access_block.main 2>/dev/null
terraform state rm module.s3.aws_s3_bucket_versioning.main 2>/dev/null
terraform state rm module.s3.aws_s3_bucket_server_side_encryption_configuration.main 2>/dev/null
terraform state rm module.s3.aws_s3_object.init_script 2>/dev/null
terraform state rm module.s3.null_resource.destroy_warning 2>/dev/null
terraform destroy "$@"
