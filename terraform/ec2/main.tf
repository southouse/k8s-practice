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
    key = "interview/services/ec2/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "brandi-tfstate-lock"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-*"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  for_each = local.ec2_instances

  name = "${local.common_prefix}-${each.key}"

  ami                    = data.aws_ami.amazon_linux_2.image_id
  instance_type          = each.value.instance_type
  key_name               = module.key_pair.key_pair_name
  monitoring             = true

  vpc_security_group_ids = each.value.vpc_security_group_ids
  
  subnet_id              = local.public_subnets[0]

  associate_public_ip_address = true

  user_data_base64 = base64encode(local.common_user_data)
  iam_instance_profile = local.iam_instance_profile_id

  root_block_device = [
    {
      encrypted = true
      volume_type = "gp3"
      throughput = 125
      volume_size = 30
    }
  ]

  tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-${each.key}"
        })
    )}"

    volume_tags	= "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}-${each.key}"
        })
    )}"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = local.common_prefix
  create_private_key = true

  tags = "${merge(
        local.common_tags,
        tomap ({
            "Name" = "${local.common_prefix}"
        })
    )}"
}