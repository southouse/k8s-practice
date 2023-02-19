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
    key = "interview/services/sg/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "brandi-tfstate-lock"
  }
}

# Security group 설정
module "app_security_groups" {
    source = "terraform-aws-modules/security-group/aws"

    for_each = local.ingress_security_groups

    use_name_prefix = false
    name        = "${local.common_prefix}-${each.key}"
    description = "${local.common_prefix}-${each.key}"
    vpc_id      = "${local.vpc_id}"

    ingress_cidr_blocks      = "${each.value.ingress_cidr_blocks}"
    ingress_with_cidr_blocks = [
        {
            from_port = "${each.value.port}"
            to_port = "${each.value.port}"
            protocol = "tcp"
        }
    ]

    egress_cidr_blocks = ["0.0.0.0/0"]
    egress_rules = ["all-tcp"]

    tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-${each.key}"
        })
    )}"
}

module "eks_cluster_sg" {
    source = "terraform-aws-modules/security-group/aws"

    use_name_prefix = false
    name        = "${local.common_prefix}-eks-cluster"
    description = "${local.common_prefix}-eks-cluster"
    vpc_id      = "${local.vpc_id}"

    ingress_with_self = [
      {
        rule = "all-all"
      },
    ]

    ingress_with_source_security_group_id = [
      {
          from_port                = 443
          to_port                  = 443
          protocol                 = "TCP"
          description              = "bastion host"
          source_security_group_id = module.app_security_groups["ssh"].security_group_id
      }
    ]

    egress_cidr_blocks = ["0.0.0.0/0"]
    egress_rules = ["all-tcp"]

    tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-eks-cluster"
        })
    )}"
}

module "eks_cluster_control_plain_sg" {
    source = "terraform-aws-modules/security-group/aws"

    use_name_prefix = false
    name        = "${local.common_prefix}-eks-control-plain"
    description = "${local.common_prefix}-eks-control-plain"
    vpc_id      = "${local.vpc_id}"

    ingress_with_source_security_group_id = [
        {
            from_port                = 443
            to_port                  = 443
            protocol                 = "TCP"
            description              = "node"
            source_security_group_id = module.eks_cluster_node_sg.security_group_id
        }
    ]

    egress_cidr_blocks = ["0.0.0.0/0"]
    egress_rules = ["all-tcp"]

    tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-eks-control-plain"
        })
    )}"
}

module "eks_cluster_node_sg" {
    source = "terraform-aws-modules/security-group/aws"

    use_name_prefix = false
    name        = "${local.common_prefix}-eks-node"
    description = "${local.common_prefix}-eks-node"
    vpc_id      = "${local.vpc_id}"

    ingress_with_self = [
      {
        rule = "all-all"
      },
    ]
    # 443, 1025-65535
    ingress_with_source_security_group_id = [
        {
          from_port                = 443
          to_port                  = 443
          protocol                 = "TCP"
          description              = "control plain"
          source_security_group_id = module.eks_cluster_control_plain_sg.security_group_id
        },
        {
          from_port                = 1025
          to_port                  = 65535
          protocol                 = "TCP"
          description              = "control plain"
          source_security_group_id = module.eks_cluster_control_plain_sg.security_group_id
        }
    ]

    egress_cidr_blocks = ["0.0.0.0/0"]
    egress_rules = ["all-tcp"]

    tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-eks-node"
        })
    )}"
}