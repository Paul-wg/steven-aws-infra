resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-eip"
    name        = "Nebulas-host"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eip_association" "main" {
  instance_id   = var.instance_id
  allocation_id = aws_eip.main.id
}
