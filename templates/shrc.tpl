#!/bin/sh
export AWS_ACCESS_KEY_ID=${aws_access_key}
export AWS_SECRET_ACCESS_KEY=${aws_secret_key}
export AWS_DEFAULT_REGION=${aws_region}

export PATH=$PATH:/tmp/port-builder/bin

# vim:set ft=sh:
