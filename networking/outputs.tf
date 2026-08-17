output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ip" {
  description = "The static public IP address of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "alb_security_group_id" {
  description = "The ID of the ALB Security Group"
  value       = aws_security_group.alb.id
}

output "compute_security_group_id" {
  description = "The ID of the Compute Security Group"
  value       = aws_security_group.compute.id
}

output "rds_security_group_id" {
  description = "The ID of the RDS Security Group"
  value       = aws_security_group.rds.id
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR block of the VPC"
}

output "rds_sg_id" {
  value       = aws_security_group.rds.id
  description = "ID of the RDS Security Group"
}
