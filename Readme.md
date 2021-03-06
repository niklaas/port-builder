# Introduction

Building [FreeBSD][4] ports for a variety of servers and clients takes
a lot of computational resources. Since mine are sparse, using the cloud
for building is attractive. This repository provides a skeleton for
creating a temporary [poudriere][1] build machine running as an [EC2
instance][2] on [Amazon AWS][3]. The machine is created with the help of
[Terraform][7] and multiple `sh` scripts.

The approach offers some outstanding characteristics: The skeleton is
split into two layers: one for permanent, and one for temporary cloud
infrastructure -- storage and build machine respectively. While building,
poudriere's state is saved on an EBS. When building is completed, the
packages are stored on a S3 bucket. In sum, this offers two huge
advantages:

1. Since poudriere's state is on an EBS, created ports trees, jails and
   packages are stored independently from the build machine itself. Thus,
   you can deploy a very powerful machine in the cloud, use and pay it
   only as long as you really need it, and destroy it afterwards. The next
   time you want to compile packages, simply deploy a new instance -- it
   will re-attach the EBS and already created ports trees, jails, and
   packages are at hand.

2. Serving the bucket as static website, the packages can be made
   available for any FreeBSD machine easily.

The idea was inspired by [JoergFiedler/freebsd-build-machine][5] using
[Vagrant][6], its [AWS Provider][9], and [Ansible][10]. I prefer my
approach because Terraform, on the contrary to Vagrant, was originally
built for the cloud. Additionally, no knowledge of Ansible is necessary to
understand what is actually happening: despite Terraform's configuration
files everything is `sh`. This is up for discussion and I'm happy for any
suggested improvement.

# Prerequisites

Some tasks the skeleton cannot handle for you automagically yet. The
following is a list of things you must take care of manually.

1. You must subscribe to Amazon AWS and have your "Access Key" and "Secret
   Key" at hand.

2. If you don't have one, create a SSH keyfile that is *not*
   password-protected (with its corresponding public key
   `insecure-keyfile.pub`) e.g., `ssh-keygen -t rsa -b 4096 -N '' -f
   ~/.ssh/insecure-keyfile`. Remember where you put that file.

3. You need some basic understanding of Terraform and poudriere. While
   this skeleton automates a lot, it is not as user-friendly as it should
   be. So you should be aware of sharp edges.

# Step-by-step Guide

0. Install Terraform from [the official download page][8]. Place it
   somewhere in your `$PATH` to ease execution.

   Note: Because of a bug, I highly recommend using `terraform` version
   0.8.8 (not the newer 0.9.x branch).

1. Clone this repository to some place of your liking. `cd` into the
   directory of the repository.

2. Copy `terraform.tfvars.example` to `terraform.tfvars` and open the
   latter. Adjust the variables accordingly i.e.,

   - `s3_bucket_name` is the name of the bucket where the build machine
     stores the compiled packages. Later you will access these packages
     from there.

   - `ssh_key` is the *private* part of your insecure keyfile i.e., in the
     case above it would be `~/.ssh/insecure-keyfile`. Terraform will upload
     its public part to AWS and associate it with the build machine.

   - `build_trees`, `build_jails`, and `build_sets` are special as they
     need the most time configuring. Here you start deciding how and which
     packages `poudriere` shall build for you.

     In the example given, `poudriere` will create a ports tree named
     "default". Further it will create a jail with method `svn+https`,
     call it "11armv6", create it according to the `arm.armv6`
     architecture, and base it on `release/11.0.1`. As you can see, you
     supply download method, name, architecture, and release separated by
     `_`. Last but not least, `poudriere` assumes a set called "default".

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
   a `pkglist` that fits to a combination provided.

4. Configuring what to build exactly is a bit difficult. Nevertheless,
   this makes it possible to build a variety of different package sets and
   preserves the versatility of `poudriere`. Especially custom options,
   port blacklists, custom `poudriere.conf`, `make.conf` and `src.conf`
   files can all be set as documented in `poudriere(8)`. The corresponding
   `poudriere.d` directory you can find in `uploads/poudriere.d`.

5. As you might have already noticed, the skeleton consists of two parts:
   `1-storage` and `2-build-machine`. Each of these is, according to
   Terraform's principles, one "layer". The structure makes it possible to
   deploy a consistent, permanent and an inconsistent, temporary part of
   infrastructure in the cloud. The first part creates an EBS and a S3
   bucket. The EBS will be used for storing a ZFS pool that comprises
   poudriere's data output (created ports trees, jails, packages, etc.).
   The S3 bucket is used to store the package repository and poudriere's
   configuration.

   Thus, when configuration is all set you `cd 1-storage` and run
   `terraform apply`. You will be asked about the size of the EBS. The
   size highly depends on the amount of ports trees, jails, and packages
   you plan to set-up.

    * If you want to import an already existing bucket that has a folder
      structure as required by this script, you can do so by executing
      `terraform import aws_s3_bucket.packages <bucket-name>` within
      `1-storage`. This will import the bucket into terraform's current
      state.

    * The same works for an EBS volume, in case you already created one but
      lost your terraform state. Execute `terraform import
      aws_ebs_volume.poudriere <vol-id>` in `1-storage`.
   
   Next, you `cd ../2-build-machine` and run `terraform apply` to create
   the build machine. You will be asked to specify the instance type. This
   mainly depends on the amount of money and time you want to spend. For
   testing, it makes sense to use an `t2.micro` instance.

    * You can find an overview of available instances (and there
      corresponding key) at [Amazon EC2 Instance
      Types](https://aws.amazon.com/ec2/instance-types). I recommend general
      purpose instances such as M4.

    * [AWS Simple Monthly
      Calculator](http://calculator.s3.amazonaws.com/index.html) can help you
      to get an idea how much usage might cost.

6. Once the infrastructure was deployed, run `./init-ssh` to connect to
   the machine.

7. Your're now on the remote machine. Start `tmux` and run `sudo
   build-ports` (it is important to run this command as root). This will
   start the build process (as complicated as you configured it).
   Depending on the amount of jails and packages that are created, this
   will take a while. When the build process itself is finished, the
   packages and poudriere's configuration are uploaded to the S3 bucket.

8. When you're done, run `sudo zpool export tank` on the remote side. This
   will release the attached EBS drive. If you don't, the builder cannot
   be destroyed with the next command.

9. Don't forget to run `terraform destroy` *within* `2-build-machine`.
   Otherwise your Amazon AWS bill will rise. Do *not* destroy the first
   layer (`1-storage`) because it holds both the EBS and S3 bucket.

10. Let your FreeBSD clients' `pkg` know about the S3 bucket. They can
    find packages under `http://<s3_bucket_URL>/pkg`.

The next time you want to compile packages, you don't need to re-create
the `1-storage` layer. Only run `terraform apply` on the second layer
`2-build-machine`. When doing so, terraform will re-attach the EBS, the
build machine will mount the ZFS pool, and compilation can continue where
it stopped the last time.

# Structure of `2-build-machine`

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

- hashicorp/terraform#13423 : Too many SSH connection attempts result in
  huge disk usage (at least for me)

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
