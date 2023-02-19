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

data "terraform_remote_state" "sg" {
    backend = "s3"

    config = {
        bucket = "brandi-tfstate"
        key = "interview/services/sg/terraform.tfstate"
        region = "${var.region}"
    }
}

data "terraform_remote_state" "iam" {
    backend = "s3"

    config = {
        bucket = "brandi-tfstate"
        key = "interview/services/iam/terraform.tfstate"
        region = "${var.region}"
    }
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
    public_subnets = "${data.terraform_remote_state.vpc.outputs.public_subnets}"
    private_subnets = "${data.terraform_remote_state.vpc.outputs.private_subnets}"

    iam_instance_profile_id = "${data.terraform_remote_state.iam.outputs.iam_instance_profile_id}"

    app_security_groups_id = "${data.terraform_remote_state.sg.outputs.app_security_groups_id}"

    ec2_instances = {
        bastion = {
            name = "bastion",
            instance_type = "t2.micro",
            vpc_security_group_ids = [
                "${data.terraform_remote_state.sg.outputs.app_security_groups_id.ssh}"
            ],
        }
    }

    common_user_data = <<-EOT
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

yum update -y
yum install -y telnet

# timezone
rm /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# locale
localectl set-locale LANG=ko_KR.utf8
EOT
}