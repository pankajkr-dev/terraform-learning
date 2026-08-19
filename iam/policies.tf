# 1. Custom policy for reading DB secrets & SSM parameters
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

output "app_secrets_policy_arn" {
  value = aws_iam_policy.app_secrets_policy.arn
}