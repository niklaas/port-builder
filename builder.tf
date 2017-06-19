variable "s3_bucket_name" {
    default = "klaas-freebsd-packages"
}

variable "build_trees" {
    default = "default"
}

variable "build_jails" {
    default = "svn+https_11armv6_arm.armv6_release/11.0.1"
}

variable "build_sets" {
    default = "default"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}


variable "computing_power" {}
variable "instance_types" {
    type = "map"
    default = {
        micro = "t2.micro"
        large = "c3.2xlarge"
    }
}

variable "freebsd_11_0_ami" {
    type = "map"
    default = {
        us-east-1      = "ami-6ceaab7b"
        us-west-1      = "ami-a3f9b7c3"
        us-west-2      = "ami-6926f809"
        sa-east-1      = "ami-a1ff6dcd"
        eu-west-1      = "ami-36581e45"
        eu-central-1   = "ami-2352ae4c"
        ap-northeast-1 = "ami-a236e9c3"
        ap-northeast-2 = "ami-a49044ca"
        ap-southeast-1 = "ami-c39337a0"
        ap-southeast-2 = "ami-5920133a"
        ap-south-1     = "ami-7c3a4e13"
    }
}

variable "ssh_key" {
    default = "~/.ssh/id_rsa"
}

data "template_file" "build-ports" {
    template = "${file("templates/build-ports.tpl")}"

    vars {
        trees = "${var.build_trees}"
        jails = "${var.build_jails}"
        sets  = "${var.build_sets}"
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

resource "aws_key_pair" "port-builder" {
    key_name    = "port-builder"
    public_key  = "${file("${var.ssh_key}.pub")}"
}

resource "aws_instance" "freebsd-builder" {
    ami           = "${lookup(var.freebsd_11_0_ami, var.aws_region)}"
    instance_type = "${lookup(var.instance_types, var.computing_power, "t2.micro")}"
    key_name      = "${aws_key_pair.port-builder.key_name}"

    user_data = "${data.template_file.init.rendered}"

    instance_initiated_shutdown_behavior = "terminate"

    root_block_device = {
        volume_size = "20"
        delete_on_termination = "true"
    }

    connection {
        type = "ssh"
        user = "ec2-user"
        private_key = "${file("${var.ssh_key}")}"
        timeout = "10m"
    }

    provisioner "local-exec" {
        command = "echo ssh -i ${var.ssh_key} ec2-user@${self.public_dns} > init-ssh && chmod +x init-ssh"
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
