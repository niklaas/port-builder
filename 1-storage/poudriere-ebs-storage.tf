resource "aws_ebs_volume" "poudriere" {
    availability_zone = "${aws_instance.freebsd-builder.availability_zone}"
    size = 20
}
