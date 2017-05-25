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

0. Install Terraform from [the official download page][8].

1. `cd` into the directory of this skeleton.

2. `terraform apply` on the local machine. This will create the build
   machine on AWS.

3. Once the infrastructure was deployed, run `./init-ssh` to connect to
   the machine.

4. Your're now on the remote machine. Start `tmux` and run `build-ports`.

# Structure of the Skeleton

- `builder.tf` is the most important file. It includes the rules for
  `terraform` on how to create the infrastructure.
- `init-ssh` is automatically created when deploying the infrastructure. It
  includes a simple `ssh` command that lets you connect to the correct
  instance.
- `templates` includes several template files that are converted according to
  your configuration/use case when deploying the infrastructure.
    - The file created from `init.tpl` is passed to the build machine even
      before it actually started. It configures the machine to install some
      packages during boot time and sets up `sudo` for the user `ec2-user`.
    - The file created from `shrc.tpl` sets up environment variables for the
      user `ec2-user`.
    - The script created from `upload-to-s3` is used to upload the ports that
      were built to S3.
- `uploads` includes several scripts and configuration files that are needed
  for the machine to build ports properly.
    - The script `bin/build-ports` is used to build the ports.

Not completed yet... To be done...

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
