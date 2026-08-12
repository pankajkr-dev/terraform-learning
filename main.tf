# Phase 1: Networking Module
module "networking" {
  source = "./networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# Phase 2: IAM Module
module "iam" {
  source = "./iam"

  aws_region   = var.aws_region
  environment  = var.environment
  project_name = var.project_name
}