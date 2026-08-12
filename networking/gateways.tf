# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Project     = "ContainerizedWebPlatform"
    Terraform   = "true"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    Project     = "ContainerizedWebPlatform"
    Terraform   = "true"
  }
}

# NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.environment}-nat-gw"
    Environment = var.environment
    Project     = "ContainerizedWebPlatform"
    Terraform   = "true"
  }

  depends_on = [aws_internet_gateway.main]
}