resource "aws_sns_topic" "drift_alerts" {
  name = "${var.environment}-terraform-drift-alerts"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "drift_email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.drift_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "drift_sns_topic_arn" {
  description = "ARN of the SNS topic for Terraform drift alerts"
  value       = aws_sns_topic.drift_alerts.arn
}