# 1. Attach standard AWS managed policy for ECS Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. Custom policy for reading app secrets & SSM parameters
resource "aws_iam_policy" "app_secrets_policy" {
  name        = "${var.environment}-app-secrets-policy"
  description = "Allows containerized application to read DB secrets and SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-app-secrets-policy"
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}

# 3. Attach secrets policy to Application Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}