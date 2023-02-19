variable "region" {
    default = "ap-northeast-2"
}

variable "env" {
    default = "interview"
}

data "terraform_remote_state" "vpc" {
    backend = "s3"

    config = {
        bucket = "brandi-tfstate"
        key = "interview/services/vpc/terraform.tfstate"
        region = "${var.region}"
    }
}

variable "office_ip" {
  default = "1.231.225.206/32"
}

locals {
    common_tags = tomap(
        {
            "Terraform" = "True", 
            "Environment" = "${var.env}"
        }
    )

    common_prefix = "${var.env}-brandi"

    vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
    vpc_cidr = "${data.terraform_remote_state.vpc.outputs.vpc_cidr_block}"

    ingress_security_groups = {
        ssh = {
            port = 22,
            ingress_cidr_blocks = ["0.0.0.0/0"] # TODO 수정
        },
        https = {
            port = 443,
            ingress_cidr_blocks = ["0.0.0.0/0"]
        },
        efs = {
            port = 2049,
            ingress_cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
        }
    }
}