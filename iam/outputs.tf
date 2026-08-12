output "permissions_boundary_arn" {
  description = "ARN of the Permissions Boundary policy"
  value       = aws_iam_policy.permissions_boundary.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS Application Task Role"
  value       = aws_iam_role.ecs_task_role.arn
}