# ==========================================
# S3 BUCKET FOR TERRAFORM REMOTE STATE
# ==========================================
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "dev-terraform-state-pankaj-2026-v2"
  force_destroy = true

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_acl" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==========================================
# DYNAMODB TABLE FOR STATE LOCKING
# ==========================================
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "dev-terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}