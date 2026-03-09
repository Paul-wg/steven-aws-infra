variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints for SSM (set true for first env, false for subsequent)"
  type        = bool
  default     = true
}
