terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "s3" {
  source       = "./modules/s3"
  bucket_name  = var.s3_bucket_name
  environment  = var.environment
  project_name = var.project_name
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_id               = var.vpc_id
  aws_region           = var.aws_region
  environment          = var.environment
  project_name         = var.project_name
  create_vpc_endpoints = var.create_vpc_endpoints
}

module "rds" {
  source                = "./modules/rds"
  db_subnet_ids         = module.vpc.db_subnet_ids
  db_security_group_id  = module.vpc.db_security_group_id
  aurora_engine_version = var.aurora_engine_version
  aurora_instance_class = var.aurora_instance_class
  environment           = var.environment
  project_name          = var.project_name
  
  depends_on = [module.vpc]
}

module "ec2" {
  source           = "./modules/ec2"
  vpc_id           = var.vpc_id
  subnet_id        = var.subnet_id
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  environment      = var.environment
  project_name     = var.project_name
  iam_instance_profile = module.s3.ec2_instance_profile_name
  s3_bucket_name   = var.s3_bucket_name
  s3_bucket_id     = module.s3.bucket_name
  aws_region          = var.aws_region
  db_cluster_endpoint = module.rds.cluster_endpoint
  db_secret_name      = "nebulas-${var.environment}-aurora-password"

  depends_on = [
    module.s3.bucket_ready,
    module.s3.init_script_uploaded,
    module.rds
  ]
}

module "eip" {
  count        = var.allocate_eip ? 1 : 0
  source       = "./modules/eip"
  environment  = var.environment
  project_name = var.project_name
}
