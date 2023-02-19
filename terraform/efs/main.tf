provider "aws" {
  region = "${var.region}"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
 
  backend "s3" {
    bucket = "brandi-tfstate"
    key = "interview/services/ebs/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "brandi-tfstate-lock"
  }
}

resource "aws_efs_file_system" "delete_evicted_pod_pv" {
  tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}"
            "kubernetes.io/created-for/pvc/name" = "delete-evicted-pod-pvc"
        })
    )}"
}

resource "aws_efs_mount_target" "mount" {
  file_system_id  = aws_efs_file_system.delete_evicted_pod_pv.id
  subnet_id       = local.private_subnets[0]
  security_groups = [local.app_security_groups_id.efs]
}