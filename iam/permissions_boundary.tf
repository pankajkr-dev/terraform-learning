resource "aws_iam_policy" "permissions_boundary" {
  name        = "${var.environment}-permissions-boundary"
  description = "Permissions boundary setting maximum guardrails for application roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowedServices"
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*",
          "logs:*",
          "s3:*",
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyIAMPolicyDeletion"
        Effect = "Deny"
        Action = [
          "iam:DeletePolicy",
          "iam:DeleteRolePermissionsBoundary"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-permissions-boundary"
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}