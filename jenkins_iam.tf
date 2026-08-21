# IAM Role for Jenkins EC2 Instance
resource "aws_iam_role" "jenkins_deployer" {
  name                 = "${var.environment}-jenkins-deployer-role"
  permissions_boundary = module.iam.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Scoped Policy for Deployment Infrastructure
resource "aws_iam_role_policy" "jenkins_deployer_policy" {
  name = "${var.environment}-jenkins-deployer-policy"
  role = aws_iam_role.jenkins_deployer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*", "ecs:*", "eks:*", "s3:*", "dynamodb:*", "rds:*", "elasticloadbalancing:*", "iam:*"]
        Resource = "*"
      }
    ]
  })
}

# Attach to EC2 Instance Profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.environment}-jenkins-instance-profile"
  role = aws_iam_role.jenkins_deployer.name
}