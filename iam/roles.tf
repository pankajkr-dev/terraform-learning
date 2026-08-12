# Trust policy allowing ECS tasks to assume these roles
data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# 1. ECS Task Execution Role (Used by AWS ECS Agent)
resource "aws_iam_role" "ecs_task_execution_role" {
  name                 = "${var.environment}-ecs-task-execution-role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_trust.json
  permissions_boundary = aws_iam_policy.permissions_boundary.arn

  tags = {
    Name        = "${var.environment}-ecs-task-execution-role"
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}

# 2. ECS Task Role (Used by the Application at Runtime)
resource "aws_iam_role" "ecs_task_role" {
  name                 = "${var.environment}-ecs-task-role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_trust.json
  permissions_boundary = aws_iam_policy.permissions_boundary.arn

  tags = {
    Name        = "${var.environment}-ecs-task-role"
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}