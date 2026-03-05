resource "random_password" "master" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-${var.environment}-aurora-master-password"

  tags = {
    Name        = "${var.project_name}-${var.environment}-aurora-master-password"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.master.result
  })
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-${var.environment}-aurora-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-aurora-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "nebulas-aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = var.aurora_engine_version
  database_name           = "nebuladb"
  master_username         = "postgres"
  master_password         = random_password.master.result
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [var.db_security_group_id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"

  tags = {
    Name        = "nebulas-aurora-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier         = "nebulas-aurora-instance"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = {
    Name        = "nebulas-aurora-instance"
    Environment = var.environment
    Project     = var.project_name
  }
}
