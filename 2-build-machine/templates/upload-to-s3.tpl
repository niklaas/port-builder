#!/bin/sh
export AWS_ACCESS_KEY_ID=${aws_access_key}
export AWS_SECRET_ACCESS_KEY=${aws_secret_key}
export AWS_DEFAULT_REGION=${aws_region}

aws s3 sync /usr/local/etc/poudriere.d/options/          s3://${s3_bucket_name}/pdr/options --acl 'public-read' --only-show-errors
aws s3 sync /usr/local/poudriere/data/logs/              s3://${s3_bucket_name}/pdr/logs    --acl 'public-read' --only-show-errors

for dir in /usr/local/poudriere/data/packages/*/
do
    aws s3 sync "$dir.latest/" "s3://${s3_bucket_name}/pkg/$(basename $dir)" \
        --acl 'public-read' \
        --only-show-errors
done

# vim:set ft=sh:
