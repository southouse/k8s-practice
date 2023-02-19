variable "region" {
    default = "ap-northeast-2"
}

variable "env" {
    default = "interview"
}

data "terraform_remote_state" "sg" {
    backend = "s3"

    config = {
        bucket = "brandi-tfstate"
        key = "interview/services/sg/terraform.tfstate"
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

    app_security_groups_id = "${data.terraform_remote_state.sg.outputs.app_security_groups_id}"
}