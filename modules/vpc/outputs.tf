output "db_subnet_ids" {
  description = "List of private subnet IDs for database"
  value       = aws_subnet.db_private[*].id
}

output "db_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.db_private[*].cidr_block
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
