data "aws_vpc" "main" {
  id = var.vpc_id
}

# Private subnets are pre-existing and permanently managed outside Terraform.
# Never created or destroyed by this module — looked up by tag only.
# Shared across environments (dev + prod use same subnets).
data "aws_subnets" "db_private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["nebulas-db-subnet-*"]
  }
}

# --- Per-environment resources ---

resource "aws_security_group" "db" {
  name        = "nebulas-${var.environment}-db-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "PostgreSQL from within VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name        = "nebulas-${var.environment}-db-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# --- Shared VPC resources (created once, used by all environments) ---
# Set create_vpc_endpoints = true for the first env, false for subsequent envs.

resource "aws_security_group" "ssm_endpoint" {
  count       = var.create_vpc_endpoints ? 1 : 0
  name        = "ssm-endpoint-sg"
  description = "Security group for SSM VPC endpoints (shared across envs)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "ssm-endpoint-sg"
    Project = var.project_name
  }
}

resource "aws_vpc_endpoint" "ssm" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.db_private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint[0].id]
  private_dns_enabled = true

  tags = {
    Name    = "ssm-endpoint"
    Project = var.project_name
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.db_private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint[0].id]
  private_dns_enabled = true

  tags = {
    Name    = "ssmmessages-endpoint"
    Project = var.project_name
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.db_private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint[0].id]
  private_dns_enabled = true

  tags = {
    Name    = "ec2messages-endpoint"
    Project = var.project_name
  }
}
