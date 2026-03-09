variable "db_subnet_ids" {
  description = "List of subnet IDs for Aurora"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for Aurora"
  type        = string
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
}

variable "aurora_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}
