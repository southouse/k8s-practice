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
    key = "interview/services/eks/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "brandi-tfstate-lock"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = "interview"
  cluster_version = "1.24"

  # cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # TODO CIDR 수정
  # cluster_endpoint_public_access_cidrs = [
  #   "0.0.0.0/0"
  # ]

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  iam_role_additional_policies = {
    additional = local.eks_iam_policy_arn
  }

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnets

  cluster_security_group_id = local.eks_cluster_sg_id
  cluster_additional_security_group_ids = [local.eks_cluster_control_plain_sg_id]
  node_security_group_enable_recommended_rules = true

  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

  cluster_security_group_additional_rules = {
    ingress_self_all = {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    ingress_bastion_security_group_id = {
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = local.app_security_groups_id.ssh
    }
  }

  # create_node_security_group = true
  node_security_group_additional_rules = {
    ingress_self_all = {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    ingress_with_source_security_group_id = {
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = local.eks_cluster_control_plain_sg_id
    },
    ingress_with_source_security_group_id = {
      protocol                 = "tcp"
      from_port                = 1025
      to_port                  = 65535
      type                     = "ingress"
      source_security_group_id = local.eks_cluster_control_plain_sg_id
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3a.medium"]

    # iam_role_additional_policies = {
    #   additional = local.eks_efs_csi_iam_policy_arn
    # }
  }

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      labels = "${merge(
          local.common_tags,
          tomap ({
              "Name" = "${local.common_prefix}"
              "ondemand" = "True"
          })
      )}"

      tags = "${merge(
          local.common_tags,
          tomap ({
              "Name" = "${local.common_prefix}-default-node-group"
          })
      )}"
    }
  }

  # aws-auth configmap
  # TODO IAM USER에서 IAM ROLE로 변경
  # create_aws_auth_configmap = true
  # manage_aws_auth_configmap = true

  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:aws:iam::66666666666:role/role1"
  #     username = "role1"
  #     groups   = ["system:masters"]
  #   },
  # ]

  # aws_auth_users = [
  #   {
  #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/southouse"
  #     username = "southouse"
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/root"
  #     username = "root"
  #     groups   = ["system:masters"]
  #   }
  # ]

  # aws_auth_accounts = [
  #   data.aws_caller_identity.current.account_id
  # ]

  tags = "${merge(
          local.common_tags,
          tomap ({
              "Name" = "${local.common_prefix}"
          })
      )}"
}