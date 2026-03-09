data "aws_vpc" "main" {
  id = var.vpc_id
}

# Private subnets are pre-existing and permanently managed outside Terraform.
# Never created or destroyed by this module — looked up by tag only.
data "aws_subnets" "db_private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-${var.environment}-db_subnet_*"]
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
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
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.db_private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-endpoint"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.db_private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssmmessages-endpoint"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.db_private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2messages-endpoint"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "ssm_endpoint" {
  name        = "${var.project_name}-${var.environment}-ssm-endpoint-sg"
  description = "Security group for SSM VPC endpoints"
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
    Name        = "${var.project_name}-${var.environment}-ssm-endpoint-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}
