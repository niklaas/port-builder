# Introduction

Building [FreeBSD][4] ports for a variety of servers and clients takes
a lot of computational resources. Since mine are sparse, using the cloud
for building is attractive. This repository provides a skeleton for
creating a temporary [poudriere][1] build machine running as an [EC2
instance][2] on [Amazon AWS][3]. The machine is created with the help of
[Terraform][7] and multiple `sh` scripts (to KISS).

The idea was inspired by [JoergFiedler/freebsd-build-machine][5] using
[Vagrant][6], its [https://github.com/mitchellh/vagrant-aws](AWS
Provider), and [https://ansible.com](Ansible).

# Workflow

0. Install Terraform from ...

1. `terraform apply` on the local machine

# Structure of the Skeleton

[uploads/bin/build-ports]

# Planned Features

* Provision HTTP server (probably www/thttpd) to monitor build process
* Enable downloading already built packages to prevent rebuilding them

# Issues

## Build works but moving packages doesn't work

At the end of the build:

```
warning: Skipping file
/usr/local/poudriere/data/packages/11armv6-default-py35/.latest. File does
not exist.
warning: Skipping file
/usr/local/poudriere/data/packages/11armv6-default-py35/.real_1490130936.
File does not exist.
warning: Skipping file
/usr/local/poudriere/data/logs/bulk/11armv6-default-py35/latest/2017-03-21_21h07m18s.
File does not exist.
```

And symbolic links in `/usr/local/poudriere/data/packages` are weird.



[1]: https://github.com/freebsd/poudriere

[2]: https://aws.amazon.com/ec2/instance-types

[3]: https://aws.amazon.com

[4]: https://www.freebsd.org

[5]: https://github.com/JoergFiedler/freebsd-build-machine

[6]: https://www.vagrantup.com

[7]: https://www.terraform.io
