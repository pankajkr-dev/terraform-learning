# ==========================================
# 1. RANDOM PASSWORD GENERATOR
# ==========================================
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ==========================================
# 2. AWS SECRETS MANAGER FOR DB CREDENTIALS
# ==========================================
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "dev-db-credentials"
  recovery_window_in_days = 0 # Allows immediate cleanup during terraform destroy

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    username = "dbadmin"
    password = random_password.db_password.result
    database = "devdb"
  })
}

# ==========================================
# 3. DB SUBNET GROUP (PRIVATE SUBNETS)
# ==========================================
resource "aws_db_subnet_group" "main" {
  name       = "dev-db-subnet-group"
  subnet_ids = module.networking.private_subnet_ids

  tags = {
    Name        = "dev-db-subnet-group"
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

# ==========================================
# 4. RDS POSTGRESQL INSTANCE
# ==========================================
resource "aws_db_instance" "postgres" {
  identifier             = "dev-postgres-db"
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "postgres"
  engine_version         = "18.3"
  instance_class         = "db.t3.micro"
  db_name                = "devdb"
  username               = "dbadmin"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.networking.rds_sg_id]

  publicly_accessible = false
  skip_final_snapshot = true
  multi_az            = false

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}