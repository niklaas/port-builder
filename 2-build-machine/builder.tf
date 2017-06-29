provider "aws" {
    region     = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

data "terraform_remote_state" "storage-poudriere" {
    backend = "local"
    config  = {
        path = "../1-storage/terraform.tfstate"
    }
}

resource "aws_key_pair" "port-builder" {
    key_name    = "port-builder"
    public_key  = "${file("${var.ssh_key}.pub")}"
}

resource "aws_volume_attachment" "poudriere" {
    device_name = "/dev/sdf"
    volume_id   = "${data.terraform_remote_state.storage-poudriere.ebs_id}"
    instance_id = "${aws_instance.freebsd-builder.id}"
}

resource "aws_instance" "freebsd-builder" {
    ami               = "${lookup(var.freebsd_11_0_ami, var.aws_region)}"
    instance_type     = "${lookup(var.instance_types, var.computing_power, "t2.micro")}"
    key_name          = "${aws_key_pair.port-builder.key_name}"

    availability_zone = "${data.terraform_remote_state.storage-poudriere.availability_zone}"

    user_data         = "${data.template_file.init.rendered}"

    root_block_device = {
        volume_size           = "10"
        delete_on_termination = "true"
    }

    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = "${file("${var.ssh_key}")}"
        timeout     = "10m"
    }

    provisioner "local-exec" {
        command = "echo ssh -i ${var.ssh_key} ec2-user@${self.public_dns} > init-ssh && chmod +x init-ssh"
    }

    # Creates temporary directories for port-builder and distfiles
    provisioner "remote-exec" {
        inline = [
            "mkdir -p /tmp/port-builder /tmp/distfiles"
        ]
    }

    # Uploads port-builder's necessities
    provisioner "file" {
        source      = "uploads/"
        destination = "/tmp/port-builder"
    }

    # Creates and uploads template files
    provisioner "file" {
        content     = "${data.template_file.build-ports.rendered}"
        destination = "/tmp/port-builder/bin/build-ports"
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
