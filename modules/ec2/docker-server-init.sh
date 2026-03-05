#!/bin/bash
set -e

echo "=========================================="
echo "Docker Server Initialization Script"
echo "=========================================="

# Update system
echo "Updating system packages..."
dnf update -y

# Install Docker
echo "Installing Docker..."
dnf install -y docker

# Start and enable Docker
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
echo "Adding ec2-user to docker group..."
usermod -a -G docker ec2-user

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Install useful tools
echo "Installing additional tools..."
dnf install -y tree htop git

# Install PostgreSQL 16 client
echo "Installing PostgreSQL 16 client..."
dnf install -y postgresql16

# Ensure SSM agent is running
echo "Verifying SSM agent..."
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent
systemctl status amazon-ssm-agent --no-pager

# Verify installations
echo "=========================================="
echo "Verifying installations..."
docker --version
aws --version
psql --version
tree --version
echo "SSM Agent Status:"
systemctl is-active amazon-ssm-agent

echo "=========================================="
echo "Docker Server Initialization Complete!"
echo "=========================================="
