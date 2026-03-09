resource "random_password" "master" {
  length  = 16
  special = true
}

resource "random_password" "app_user" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "nebulas-${var.environment}-aurora-password"
  recovery_window_in_days = 0

  tags = {
    Name        = "nebulas-${var.environment}-aurora-password"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username     = "postgres"
    password     = random_password.master.result
    app_username = "nebulas"
    app_password = random_password.app_user.result
    dbname       = "nebulasdb"
    schema       = "nebulas"
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
  cluster_identifier      = "nebulas-aurora-${var.environment}"
  engine                  = "aurora-postgresql"
  engine_version          = var.aurora_engine_version
  database_name           = "nebulasdb"
  master_username         = "postgres"
  master_password         = random_password.master.result
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [var.db_security_group_id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"

  tags = {
    Name        = "nebulas-aurora-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier         = "nebulas-aurora-${var.environment}-instance"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  tags = {
    Name        = "nebulas-aurora-${var.environment}-instance"
    Environment = var.environment
    Project     = var.project_name
  }
}
