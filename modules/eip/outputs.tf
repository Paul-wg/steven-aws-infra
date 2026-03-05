output "public_ip" {
  description = "Elastic IP public address"
  value       = aws_eip.main.public_ip
}

output "allocation_id" {
  description = "Elastic IP allocation ID"
  value       = aws_eip.main.id
}
