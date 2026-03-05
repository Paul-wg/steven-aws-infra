output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_private_ip" {
  description = "EC2 private IP"
  value       = module.ec2.private_ip
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = module.ec2.public_ip
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

output "eip_public_ip" {
  description = "Elastic IP public address"
  value       = var.allocate_eip ? module.eip[0].public_ip : null
}

output "eip_allocation_id" {
  description = "Elastic IP allocation ID"
  value       = var.allocate_eip ? module.eip[0].allocation_id : null
}

output "db_subnet_ids" {
  description = "Private subnet IDs for database"
  value       = module.vpc.db_subnet_ids
}

output "db_security_group_id" {
  description = "Database security group ID"
  value       = module.vpc.db_security_group_id
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = module.rds.cluster_endpoint
}

output "aurora_database_name" {
  description = "Aurora database name"
  value       = module.rds.database_name
}

output "aurora_secret_arn" {
  description = "Aurora master password secret ARN"
  value       = module.rds.secret_arn
}
