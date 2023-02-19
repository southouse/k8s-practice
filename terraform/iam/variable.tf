variable "region" {
    default = "ap-northeast-2"
}

variable "env" {
    default = "interview"
}

locals {
    common_tags = tomap(
        {
            "Terraform" = "True", 
            "Environment" = "${var.env}"
        }
    )

    common_prefix = "${var.env}-brandi"
}