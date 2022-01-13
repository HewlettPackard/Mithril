#!/bin/bash

export S3_PATCHSET_BUCKET="s3://mithril-poc-patchset"
export PATCHSET_BUCKET="mithril-poc-patchset"

cd ./POC

tar -zcvf mithril-poc-patchset.tar.gz patches

aws s3 cp mithril-poc-patchset.tar.gz ${S3_PATCHSET_BUCKET}
aws s3api put-object-acl --bucket ${PATCHSET_BUCKET} --key mithril-poc-patchset.tar.gz --acl public-read