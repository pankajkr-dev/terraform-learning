output "alb_dns_name" {
  description = "Public DNS URL of the ALB"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "URL of the created ECR Repository"
  value       = aws_ecr_repository.app.repository_url
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "alb_arn_suffix" {
  value       = aws_lb.main.arn_suffix
  description = "ARN suffix of the Application Load Balancer for CloudWatch metrics"
}

