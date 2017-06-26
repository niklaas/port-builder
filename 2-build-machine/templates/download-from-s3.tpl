#!/bin/sh
export AWS_ACCESS_KEY_ID=${aws_access_key}
export AWS_SECRET_ACCESS_KEY=${aws_secret_key}
export AWS_DEFAULT_REGION=${aws_region}

aws s3 sync s3://${s3_bucket_name}/pkg/         /usr/local/poudriere/data/packages --only-show-errors
aws s3 sync s3://${s3_bucket_name}/pdr/options/ /usr/local/etc/poudriere.d/options --only-show-errors
aws s3 sync s3://${s3_bucket_name}/pdr/logs/    /usr/local/poudriere/data/logs     --only-show-errors

# vim:set ft=sh:
