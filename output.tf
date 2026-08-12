# Phase 1: Networking Module Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.networking.igw_id
}

output "nat_gateway_ip" {
  description = "The static public IP address of the NAT Gateway"
  value       = module.networking.nat_gateway_ip
}

# Phase 2: IAM Module Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = module.iam.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS Application Task Role"
  value       = module.iam.ecs_task_role_arn
}