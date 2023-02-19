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
    key = "interview/services/iam/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "brandi-tfstate-lock"
  }
}

module "eks_iam_policy" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

    name        = "${local.common_prefix}-eks-policy"
    path        = "/"
    description = "${local.common_prefix}-eks-policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = [
            "ec2:Describe*",
            ]
            Effect   = "Allow"
            Resource = "*"
        },
        ]
    })

    tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-eks-policy"
        })
    )}"
}

module "eks_efs_csi_iam_policy" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

    name        = "${local.common_prefix}-efs-csi-policy"
    path        = "/"
    description = "${local.common_prefix}-efs-csi-policy"

    policy = <<-EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:CreateAccessPoint"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "elasticfilesystem:DeleteAccessPoint",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOT

    tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-efs-csi-policy"
        })
    )}"
}

module "iam_assumable_role" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

    trusted_role_services = [
        "ec2.amazonaws.com"
    ]

    create_role             = true
    create_instance_profile = true

    role_name         = "${local.common_prefix}-bastion-role"
    role_requires_mfa = false

    custom_role_policy_arns = [
    ]

    tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-bastion-role"
        })
    )}"
}