terraform {
  backend "s3" {
    bucket         = "dev-terraform-state-pankaj-2026-v2"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dev-terraform-state-locks"
  }
}