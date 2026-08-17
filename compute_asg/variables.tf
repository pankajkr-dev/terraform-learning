variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name tag"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EC2 ASG"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB Security Group ID from networking module"
  type        = string
}

variable "compute_security_group_id" {
  description = "Compute Security Group ID from networking module"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type for ASG"
  type        = string
  default     = "t3.micro"
}