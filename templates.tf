data "template_file" "init" {
    template = "${file("templates/init.tpl")}"

    vars {
        firstboot_pkgs_list = "sudo awscli poudriere dialog4ports qemu-user-static tmux"
    }
}

data "template_file" "download-from-s3" {
    template = "${file("templates/download-from-s3.tpl")}"

    vars {
        s3_bucket_name = "${var.s3_bucket_name}"
        aws_access_key = "${var.aws_access_key}"
        aws_secret_key = "${var.aws_secret_key}"
        aws_region     = "${var.aws_region}"
    }
}

data "template_file" "upload-to-s3" {
    template = "${file("templates/upload-to-s3.tpl")}"

    vars {
        s3_bucket_name = "${var.s3_bucket_name}"
        aws_access_key = "${var.aws_access_key}"
        aws_secret_key = "${var.aws_secret_key}"
        aws_region     = "${var.aws_region}"
    }
}

data "template_file" "shrc" {
    template = "${file("templates/shrc.tpl")}"

    vars {
        aws_access_key = "${var.aws_access_key}"
        aws_secret_key = "${var.aws_secret_key}"
        aws_region     = "${var.aws_region}"
    }
}
