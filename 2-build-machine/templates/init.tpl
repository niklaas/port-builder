#!/bin/sh
echo 'ZFS_ENABLE="YES"' >> /etc/rc.conf
echo 'firstboot_pkgs_list="${firstboot_pkgs_list}"' >> /etc/rc.conf
mkdir -p /usr/local/etc/sudoers.d
echo 'ec2-user ALL=(ALL) NOPASSWD: ALL' >> /usr/local/etc/sudoers.d/ec2-user

# vim: set ft=sh:
