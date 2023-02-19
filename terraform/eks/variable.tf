data "aws_caller_identity" "current" {}

variable "region" {
    default = "ap-northeast-2"
}

variable "env" {
    default = "interview"
}

data "terraform_remote_state" "iam" {
    backend = "s3"

    config = {
        bucket = "brandi-tfstate"
        key = "interview/services/iam/terraform.tfstate"
        region = var.region
    }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"

    config = {
        bucket = "brandi-tfstate"
        key = "interview/services/vpc/terraform.tfstate"
        region = var.region
    }
}

data "terraform_remote_state" "sg" {
    backend = "s3"

    config = {
        bucket = "brandi-tfstate"
        key = "interview/services/sg/terraform.tfstate"
        region = var.region
    }
}

locals {
    common_tags = tomap(
        {
            "Terraform" = "True",
            "Environment" = var.env
        }
    )

    common_prefix = "${var.env}-brandi"

    eks_iam_policy_arn = data.terraform_remote_state.iam.outputs.eks_iam_policy_arn
    eks_efs_csi_iam_policy_arn = data.terraform_remote_state.iam.outputs.eks_efs_csi_iam_policy_arn

    vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
    vpc_cidr = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
    private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

    app_security_groups_id = data.terraform_remote_state.sg.outputs.app_security_groups_id
    eks_cluster_sg_id = data.terraform_remote_state.sg.outputs.eks_cluster_sg_id
    eks_cluster_control_plain_sg_id = data.terraform_remote_state.sg.outputs.eks_cluster_control_plain_sg_id
    eks_cluster_node_sg_id = data.terraform_remote_state.sg.outputs.eks_cluster_node_sg_id
}