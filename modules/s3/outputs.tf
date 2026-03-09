output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2_s3_role.arn
}

output "bucket_ready" {
  description = "S3 bucket is ready for use"
  value       = aws_s3_bucket.main.id
  depends_on  = [
    aws_s3_bucket.main,
    aws_s3_bucket_public_access_block.main,
    aws_s3_bucket_versioning.main,
    aws_s3_bucket_server_side_encryption_configuration.main
  ]
}

output "init_script_uploaded" {
  description = "Init script uploaded to S3"
  value       = aws_s3_object.init_script.id
}
