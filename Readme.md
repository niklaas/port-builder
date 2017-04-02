# Introduction

Building [FreeBSD][4] ports for a variety of servers and clients takes
a lot of computational resources. Since mine are sparse, using the cloud
for building is attractive. This repository provides a skeleton for
creating a temporary [poudriere][1] build machine running as an [EC2
instance][2] on [Amazon AWS][3]. The machine is created with the help of
[Terraform][7] and multiple `sh` scripts (to KISS).

The idea was inspired by [JoergFiedler/freebsd-build-machine][5] using
[Vagrant][6], its [AWS Provider][9], and [Ansible][10].

# Workflow

0. Install Terraform from [the official download page][8]

1. `terraform apply` on the local machine

2. Once the infrastructure was deployed, run `./init-ssh` to connect to
   the machine.

3. Start `tmux` and `build-ports`

# Structure of the Skeleton

To be done ...

# Planned Features

- [ ] Provision HTTP server (probably www/thttpd) to monitor build process
- [ ] Download already built packages from S3 to prevent rebuilding them


[1]: https://github.com/freebsd/poudriere

[2]: https://aws.amazon.com/ec2/instance-types

[3]: https://aws.amazon.com

[4]: https://www.freebsd.org

[5]: https://github.com/JoergFiedler/freebsd-build-machine

[6]: https://www.vagrantup.com

[7]: https://www.terraform.io

[8]: https://www.terraform.io/downloads.html

[9]: https://github.com/mitchellh/vagrant-aws

[10]: https://ansible.com
