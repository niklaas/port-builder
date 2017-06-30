provider "aws" {
    region     = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

data "aws_availability_zones" "available" {
    state = "available"
}

output "availability_zone" {
    value = "${aws_ebs_volume.poudriere.availability_zone}"
}
