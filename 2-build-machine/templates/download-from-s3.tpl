#!/bin/sh
export AWS_ACCESS_KEY_ID=${aws_access_key}
export AWS_SECRET_ACCESS_KEY=${aws_secret_key}
export AWS_DEFAULT_REGION=${aws_region}

# Copy poudriere configuration from S3
aws s3 sync s3://${s3_bucket_name}/pdr /usr/local/etc --only-show-errors

# vim:set ft=sh:
