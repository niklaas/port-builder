# Introduction

Building [FreeBSD][4] ports for a variety of servers and clients takes
a lot of computational resources. Since mine are sparse, using the cloud
for building is attractive. This repository provides a skeleton for
creating a temporary [poudriere][1] build machine running as an [EC2
instance][2] on [Amazon AWS][3]. The machine is created with the help of
[Terraform][7] and multiple `sh` scripts. When building is completed, the
packages are stored on a S3 bucket. Serving the bucket as static website,
the packages can be made available for any FreeBSD machine.

The idea was inspired by [JoergFiedler/freebsd-build-machine][5] using
[Vagrant][6], its [AWS Provider][9], and [Ansible][10]. I prefer my
approach because Terraform, on the contrary to Vagrant, was originally
built for the cloud. Additionally, no knowledge of Ansible is necessary to
understand what is actually happening: despite Terraform's configuration
files everything is `sh`. This is up for discussion and I'm happy for any
suggested improvement.

# Prerequisites

Some tasks the skeleton cannot handle for you automagically yet (see below
for hiccups and planned features).

1. You must subscribe to Amazon AWS and have your "Access Key" and "Secret
   Key" at hand.

2. You need an S3 bucket to store the compiled packages. Take note of the
   name of the bucket. (To serve the built packages to other FreeBSD
   machines, enable serving the bucket as static website. While this is
   not necessary for the build machine to work, it totally makes sense.)

3. Create a SSH keyfile that is not password-protected (with its
   corresponding public key `insecure-keyfile.pub`) e.g., `ssh-keygen -t
   rsa -b 4096 -N '' -f ~/.ssh/insecure-keyfile`. Remember where you put
   that file.

# Step-by-step Guide

0. Install Terraform from [the official download page][8]. Place it
   somewhere in your `$PATH` to ease execution.

1. Clone this repository to some place of your liking. `cd` into the
   directory of the repository.

2. Copy `terraform.tfvars.example` to `terraform.tfvars` and open the
   latter. Adjust the variables accordingly i.e.,

   - `s3_bucket_name` is the name of the bucket where the build machine
     stores the compiled packages. Later you will access these packages
     from there.

   - `ssh_key` is the *private* part of your insecure keyfile i.e., in
     this case it would be `~/.ssh/insecure-keyfile`. Terraform will
     upload its public part to AWS and associate it with the build
     machine.

   - `build_trees`, `build_jails`, and `build_sets` are special as they
     need the most time configuring. Here you start deciding how and which
     packages `poudriere` shall build for you.

     In the example given, `poudriere` will create a ports tree named
     "default". Further it will create a jail with method `svn+https`,
     call it "11armv6", create it according to the `arm.armv6`
     architecture, and base it on the `release/11.0.1`. As you can see,
     you supply download method, name, architecture, and release separated
     by `_`. Last but not least, `poudriere` assumes a set called "default".

     In these variables you can specify multiple entries each separated by
     space. The build script will iterate through all of them.

3. Obviously, you must also tell `poudriere` which packages to build. You
   do so by listing their portname in package lists that you create in
   `uploads/pkglists`. The name of each list must correspond to the
   `build_trees`, `build_jails`, and `build_sets` that you configured in
   `terraform.tfvars`. E.g., `uploads/pkglists/default-11armv6-default`
   contains packages for the ports tree named "default", the jail
   "11armv6", and set "default".

   As mentioned previously, the build script will iterate through all
   combinations of `build_trees`, `build_jails`, and `build_sets`.
   However, it will not build anything, if there does not exist
   a `pkglist` that fits to any combination.

4. Configuring what to build exactly is a bit difficult. Nevertheless,
   this makes it possible to build a variety of different package sets and
   preserves the versatility of `poudriere`. Especially custom options,
   port blacklists, custom `poudriere.conf`, `make.conf` and `src.conf`
   files can all be set as documented in `poudriere(8)`. The `poudriere.d`
   directory you find in `uploads/poudriere.d`.

5. When configuration is all set you can run `terraform apply` on the
   local machine. This will create the build machine on AWS. You will be
   asked to specify the  computing power. You can specify either "micro"
   or "large", which will either deploy a "t2.micro" or "c3.2xlarge"
   machine. ("Micro" can be used for testing purposes while "large" should
   give decent performance for building packages relatively quickly.)
   
   Once deployed, the build machine will automatically install `poudriere`
   and other packages. Thus, deploying the infrastructure will take some
   time. Stand by and grab some tea.

6. Once the infrastructure was deployed, run `./init-ssh` to connect to
   the machine. The file includes an `ssh` connection command that uses
   the configured `ssh` key and the public DNS record of the build
   machine.

7. Your're now on the remote machine. Start `tmux` and run `sudo
   build-ports` (it is important to run this command as root). This will
   start the build process (as complicated as you configured it).
   Depending on the amount of jails and packages that are created, this
   will take a while. When the build process itself is finished, the
   packages packages are uploaded to the S3 bucket.

8. Don't forget to run `terraform destroy` on your local machine once
   compilation is done. Otherwise your Amazon AWS bill will rise...

# Structure of the Skeleton

- `builder.tf` is the most important file. It includes the rules for
  `terraform` on how to create the infrastructure.
- `init-ssh` is automatically created by terraform when deploying the
  infrastructure. It includes a simple `ssh` command that lets you connect
  to the correct instance.
- `templates` includes several template files that are converted according
  to your configuration/use case when deploying the infrastructure.
    - The file created from `init.tpl` is passed to the build machine
      before it actually starts. It configures the machine to install some
      packages during boot time (as configured in `builder.tf` and sets up
      `sudo` for the user `ec2-user`.
    - The script `build-ports.tpl` is used to build the ports. It will be
      created according to the ports trees, jails, and sets you defined in
      `variables.tf`.
    - The file created from `shrc.tpl` sets up environment variables for
      the user `ec2-user`. This makes interaction with the S3 storage
      easier.
    - The script created from `upload-to-s3` is used to upload the
      compiled packages to S3.
- `uploads` includes several scripts and configuration files that are
  needed remotely to build the ports properly.
    - `ports/<tree-name>` can include ports that have not been uploaded to
      the official ports tree yet. According to the name of the directory,
      these will be added to the to one of the trees configured by you and
      created by the builder.
    - `poudriere.conf` is the configuration file for poudriere.
    - `poudriere.d` includes further configuration for poudriere.

# Terraform's hiccups

- terraform-providers/terraform-provider-aws#22 : Instances cannot be
  stopped, they can only be *terminated*.

  At the moment, every time the skeleton is used, a new instances is
  created i.e., already created jails, options, packages et cetera are
  lost. It would be great if, instead of being terminated, the build
  machine could be stopped as long as it is not in use, thus not costing
  money. However, when stopping (instead of terminating) a machine no data
  is lost. When there is need for an upgrade, it could be started and the
  already built jails were already at hand.

  I started to work around this with reusing a permanent EBS drive but
  have not succeeded yet (see branch ftr/perm-ebs). This would save a lot
  of time and computing power.

- hashicrop/terraform#13423 : Too many SSH connection attempts result in
  huge disk usage (at least for me)

# Planned Features

- [ ] Provision HTTP server (probably www/thttpd) to monitor build process
- [ ] Download already built packages from S3 to prevent rebuilding them
- [ ] Reuse already built jails


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
