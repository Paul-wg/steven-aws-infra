# Dev environment — used from 'wg' branch
# Usage: ./apply.sh dev
aws_region     = "ap-southeast-4"
aws_profile    = "ai-steven"
vpc_id         = "vpc-00d99c392e8a488eb"
subnet_id      = "subnet-02a6c924b93797e96"
environment    = "dev"
project_name   = "ai-steven"

# EC2
instance_type    = "t4g.micro"
root_volume_size = 30

# S3 (shared across environments)
s3_bucket_name = "ai-foundry-artifacts-apse4"

# Aurora PostgreSQL
aurora_engine_version = "16.4"
aurora_instance_class = "db.t4g.medium"

# Elastic IP
allocate_eip = true

# Shared VPC resources (endpoints created by dev, reused by prod)
create_vpc_endpoints = true
