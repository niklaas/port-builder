variable "instance_type"  { }

variable "aws_access_key" { }
variable "aws_secret_key" { }
variable "aws_region"     { }
variable "s3_bucket_name" { }


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

variable "build_trees" { }
variable "build_jails" { }
variable "build_sets"  { }
