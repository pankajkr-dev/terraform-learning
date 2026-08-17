# 1. ECR Repository for Docker Images
resource "aws_ecr_repository" "app" {
  name                 = lower("${var.environment}-${var.project_name}-repo")
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-ecr-repo"
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}