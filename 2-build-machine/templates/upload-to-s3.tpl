#!/bin/sh
export AWS_ACCESS_KEY_ID=${aws_access_key}
export AWS_SECRET_ACCESS_KEY=${aws_secret_key}
export AWS_DEFAULT_REGION=${aws_region}

# Copies poudriere configuration to S3
aws s3 sync /usr/local/etc s3://${s3_bucket_name}/pdr \
    --acl 'public-read'                               \
    --only-show-errors                                \
    --delete                                          \
    --exclude "*"                                     \
    --include "poudriere*"

# Copies built packages to S3
for dir in /usr/local/poudriere/data/packages/*/
do
    aws s3 sync "$dir.latest/" "s3://${s3_bucket_name}/pkg/$(basename $dir)" \
        --acl 'public-read' \
        --only-show-errors
done

# vim:set ft=sh:
