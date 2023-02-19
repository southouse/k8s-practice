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
    key = "interview/services/vpc/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "brandi-tfstate-lock"
  }
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "${local.common_prefix}"
    cidr = "192.168.0.0/24"

    azs = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
    
    public_subnets = ["192.168.0.0/27", "192.168.0.32/27", "192.168.0.64/27"]
    public_subnet_suffix = "public"
    
    private_subnets = ["192.168.0.96/27", "192.168.0.128/27", "192.168.0.160/27"]
    private_subnet_suffix = "private"

    database_subnets = ["192.168.0.192/27", "192.168.0.224/27"]
    database_subnet_group_name = "${local.common_prefix}-private-db-subnet-group"
    database_subnet_suffix = "private-db"

    enable_nat_gateway   = true
    single_nat_gateway   = true

    enable_dns_hostnames = true
    enable_dns_support = true

    create_database_subnet_route_table     = true

    tags = "${merge(
        local.common_tags
    )}"

    igw_tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-igw"
        })
    )}"

    nat_gateway_tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-nat-gw"
        })
    )}"

    database_subnet_group_tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-private-db-subnet-group"
        })
    )}"
}

# module "endpoints" {
#   source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

#   vpc_id             = module.vpc.vpc_id

#   endpoints = {
#     s3 = {
#       service             = "s3"
#       service_type        = "Gateway"
#       route_table_ids     = module.vpc.private_route_table_ids
#       tags                = { Name = "${local.common_prefix}-s3-gw-ep" }
#     },
#     ec2 = {
#       service             = "ec2"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       security_group_ids  = [local.app_security_groups_id.https]
#       tags                = { Name = "${local.common_prefix}-ec2-if-ep" }
#     }
#     ecr_dkr = {
#       service             = "ecr.dkr"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       security_group_ids  = [local.app_security_groups_id.https]
#       tags                = { Name = "${local.common_prefix}-ecr-dkr-if-ep" }
#     },
#     ecr_api = {
#       service             = "ecr.api"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       security_group_ids  = [local.app_security_groups_id.https]
#       tags                = { Name = "${local.common_prefix}-ecr-api-if-ep" }
#     }
#   }

#   tags = "${merge(
#         local.common_tags
#     )}"
# }