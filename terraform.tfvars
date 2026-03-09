# Centralized Parameters
aws_region     = "ap-southeast-4"
aws_profile    = "ai-steven"
vpc_id         = "vpc-00d99c392e8a488eb"  # Replace with your VPC ID
subnet_id      = "subnet-02a6c924b93797e96"  # Replace with your Subnet ID
environment    = "dev"
project_name   = "ai-steven"

# EC2 Configuration
instance_type  = "t4g.micro"
root_volume_size = 30

# S3 Configuration
s3_bucket_name = "ai-foundry-artifacts-apse4"

# Aurora PostgreSQL Configuration
aurora_engine_version = "16.4"
aurora_instance_class = "db.t4g.medium"

# Elastic IP Configuration
allocate_eip = true
