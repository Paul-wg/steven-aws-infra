resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name        = "nebulas-${var.environment}-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}
