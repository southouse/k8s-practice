provider "aws" {
  region = "${var.region}"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "<= 4.0"
    }
  }

  backend "s3" {
    bucket = "brandi-tfstate"
    key = "global/s3/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "brandi-tfstate-lock"
  }
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "brandi-tfstate"

    tags = {
        Name = "brandi-tfstate"
        Terraform = "true"
        Environment = "all"
    }
}

resource "aws_s3_bucket_acl" "terraform_state_acl" {
    bucket = aws_s3_bucket.terraform_state.id
    acl = "private"
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name = "brandi-tfstate-lock"
  hash_key = "LockID"
  read_capacity = 2
  write_capacity = 2

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "brandi-tfstate-lock-table"
    Terraform = "true"
    Environment = "all"
  }
}