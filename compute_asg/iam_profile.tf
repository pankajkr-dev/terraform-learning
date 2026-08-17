# 1. IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_asg_role" {
  name = "${var.environment}-ec2-asg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-ec2-asg-role"
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}

# 2. Attach Read-Only ECR Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "ec2_ecr_read_only" {
  role       = aws_iam_role.ec2_asg_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. Create Instance Profile to pass Role to Launch Template
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_asg_role.name
}