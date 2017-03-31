variable "s3_bucket_name" {
    default = "klaas-freebsd-packages"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}


variable "computing_power" {}
variable "instance_types" {
    type = "map"
    default = {
        small = "t2.micro"
        large = "m3.2xlarge"
    }
}

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

provider "aws" {
    region     = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

resource "aws_volume_attachment" "poudriere" {
    device_name = "/dev/sdb"
    volume_id = "${aws_ebs_volume.poudriere.id}"
    instance_id = "${aws_instance.freebsd-builder.id}"
}

resource "aws_instance" "freebsd-builder" {
    # TODO: make this map to different regions
    ami           = "ami-2352ae4c"    # FreeBSD 11.0-RELEASE
    instance_type = "${lookup(var.instance_types, var.computing_power, "t2.micro")}"
    key_name      = "ec2-user"

    user_data = "${data.template_file.init.rendered}"

    instance_initiated_shutdown_behavior = "terminate"

    root_block_device = {
        volume_size = "10"
        delete_on_termination = "true"
    }

    connection {
        type = "ssh"
        user = "ec2-user"
        private_key = "${file("/home/niklaas/.ssh/ec2-user.pem")}"
        timeout = "10m"
    }

    provisioner "local-exec" {
        command = "echo ssh -i /home/niklaas/.ssh/ec2-user.pem ec2-user@${self.public_dns} > init-ssh && chmod +x init-ssh"
    }

    provisioner "remote-exec" {
        inline = [
            "mkdir -p /tmp/port-builder /tmp/distfiles"
        ]
    }

    provisioner "file" {
        source      = "uploads/"
        destination = "/tmp/port-builder"
    }

    provisioner "file" {
        content     = "${data.template_file.download-from-s3.rendered}"
        destination = "/tmp/port-builder/bin/download-from-s3"
    }
    provisioner "file" {
        content     = "${data.template_file.upload-to-s3.rendered}"
        destination = "/tmp/port-builder/bin/upload-to-s3"
    }
    provisioner "file" {
        content     = "${data.template_file.shrc.rendered}"
        destination = "/home/ec2-user/.shrc"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mkdir -p  /usr/local/etc/poudriere.d/options /var/cache/ccache",
            "sudo cp        /tmp/port-builder/poudriere.conf /usr/local/etc",
            "sudo cp -r     /tmp/port-builder/poudriere.d/*  /usr/local/etc/poudriere.d",
            "chmod +x       /tmp/port-builder/bin/*",
        ]
    }
}

resource "aws_ebs_volume" "poudriere" {
    availability_zone = "${aws_instance.freebsd-builder.availability_zone}"
    size = 20
}
