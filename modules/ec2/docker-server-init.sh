#!/bin/bash

echo "=========================================="
echo "Docker Server Initialization Script"
echo "=========================================="

# Ensure SSM agent is running FIRST — before anything else that could fail
echo "Starting SSM agent..."
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Update system
echo "Updating system packages..."
dnf update -y

# Re-ensure SSM agent is running after update (dnf update may stop it)
echo "Re-verifying SSM agent after update..."
systemctl restart amazon-ssm-agent

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
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Install useful tools (non-critical — failures here do not affect SSM or Docker)
echo "Installing additional tools..."
dnf install -y tree htop git || echo "WARNING: Some optional tools failed to install"

# Install PostgreSQL 16 client (non-critical)
echo "Installing PostgreSQL 16 client..."
dnf install -y postgresql16 || echo "WARNING: postgresql16 install failed — skipping"

# Verify installations
echo "=========================================="
echo "Verifying installations..."
docker --version
aws --version || true
psql --version || true
echo "SSM Agent Status:"
systemctl is-active amazon-ssm-agent

echo "=========================================="
echo "Docker Server Initialization Complete!"
echo "=========================================="
