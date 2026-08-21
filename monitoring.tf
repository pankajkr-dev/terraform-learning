# ==========================================
# 1. SNS TOPIC FOR ALERTS
# ==========================================
resource "aws_sns_topic" "alerts" {
  name = "dev-infrastructure-alerts"

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

# ==========================================
# 2. SNS EMAIL SUBSCRIPTION
# ==========================================
resource "aws_sns_topic_subscription" "email_alert" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ==========================================
# 3. HIGH CPU ALARM FOR AUTOSCALING GROUP
# ==========================================
resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "dev-asg-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when ASG average CPU utilization exceeds 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = module.compute_asg.asg_name
  }

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

# ==========================================
# 4. RDS DATABASE HIGH CPU ALARM
# ==========================================
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "dev-rds-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when RDS PostgreSQL CPU utilization exceeds 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

# ==========================================
# 5. RDS DATABASE LOW STORAGE ALARM
# ==========================================
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "dev-rds-low-storage-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5000000000 # 5 GB in Bytes
  alarm_description   = "Triggers when RDS free storage drops below 5 GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

# ==========================================
# 6. ALB HTTP 5XX ERROR RATE ALARM
# ==========================================
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "dev-alb-high-5xx-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Triggers when application backend returns 10 or more 5xx HTTP server errors within 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = module.compute_asg.alb_arn_suffix
  }

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}