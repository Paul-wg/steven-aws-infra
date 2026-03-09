output "db_subnet_ids" {
  description = "List of private subnet IDs for database (pre-existing, not managed by Terraform)"
  value       = data.aws_subnets.db_private.ids
}

output "db_security_group_id" {
  description = "Security group ID for database"
  value       = aws_security_group.db.id
}

output "ssm_endpoint_ids" {
  description = "SSM VPC endpoint IDs"
  value = {
    ssm         = aws_vpc_endpoint.ssm.id
    ssmmessages = aws_vpc_endpoint.ssmmessages.id
    ec2messages = aws_vpc_endpoint.ec2messages.id
  }
}
