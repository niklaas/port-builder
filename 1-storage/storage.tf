resource "aws_ebs_volume" "poudriere" {
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    size              = "${var.ebs_size}"
}

output "ebs_id" {
    value = "${aws_ebs_volume.poudriere.id}"
}

resource "aws_s3_bucket" "packages" {
    bucket        = "${var.s3_bucket_name}"
    region        = "${var.aws_region}"
    force_destroy = "true"
    acl           = "public-read"

    website {
      index_document = "index.html"
      error_document = "error.html"
    }
}
