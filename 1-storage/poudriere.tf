variable "aws_access_key"  { }
variable "aws_secret_key"  { }
variable "aws_region"      { }

provider "aws" {
    region     = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

data "aws_availability_zones" "available" {
    state = "available"
}

resource "aws_ebs_volume" "poudriere" {
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    size              = 20
}

output "ebs_id" {
    value = "${aws_ebs_volume.poudriere.id}"
}

output "availability_zone" {
    value = "${aws_ebs_volume.poudriere.availability_zone}"
}
