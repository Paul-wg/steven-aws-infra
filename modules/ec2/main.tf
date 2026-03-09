data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  # "al2023-ami-2*" matches full AL2023 only — excludes "al2023-ami-minimal-*"
  # Full AL2023 has SSM agent pre-installed; minimal does not
  filter {
    name   = "name"
    values = ["al2023-ami-2*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = <<-EOF
              #!/bin/bash
              # Verify S3 bucket exists: ${var.s3_bucket_id}
              # Download init script from S3 (retry up to 3 times for IAM credential propagation)
              for i in 1 2 3; do
                aws s3 cp s3://${var.s3_bucket_name}/initialfiles/docker-server-init.sh /tmp/docker-server-init.sh && break
                echo "S3 download attempt $i failed, retrying in 10s..."
                sleep 10
              done

              if [ -f /tmp/docker-server-init.sh ]; then
                sed -i 's/\r$//' /tmp/docker-server-init.sh
                chmod +x /tmp/docker-server-init.sh
                /tmp/docker-server-init.sh > /var/log/docker-server-init.log 2>&1
              else
                echo "ERROR: Failed to download init script from S3 after 3 attempts" > /var/log/docker-server-init.log
              fi

              # Generate .env file — NO passwords, only Secrets Manager references
              echo "Generating .env.${var.environment} (no secrets on disk)..."
              ENV_FILE="/home/ec2-user/.env.${var.environment}"

              cat > "$ENV_FILE" << ENVEOF
              DB_SECRET_NAME=${var.db_secret_name}
              DB_SECRET_REGION=${var.aws_region}
              DB_CLUSTER_ENDPOINT=${var.db_cluster_endpoint}
              APP_ENV=${var.environment}
              SECRET_KEY=$(openssl rand -hex 32)
              CORS_ORIGINS=http://localhost:5173,http://localhost:3000
              ENVEOF

              chown ec2-user:ec2-user "$ENV_FILE"
              chmod 600 "$ENV_FILE"
              echo ".env.${var.environment} created successfully (secrets resolved at app startup via IAM role)"
              EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = {
    Name        = "nebulas-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}
