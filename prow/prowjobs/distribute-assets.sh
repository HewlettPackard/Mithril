#!/bin/bash

export S3_CUSTOMER_BUCKET="s3://mithril-customer-assets"
export CUSTOMER_BUCKET="mithril-customer-assets"

cd ./POC

tar -zcvf mithril.tar.gz bookinfo spire istio configmaps.yaml \
deploy-all.sh create-namespaces.sh cleanup-all.sh forward-port.sh create-kind-cluster.sh \
doc/poc-instructions.md demo/demo-script.sh demo/README.md demo/federation-demo.sh ../usecases/federation

aws s3 cp mithril.tar.gz ${S3_CUSTOMER_BUCKET}
aws s3api put-object-acl --bucket ${CUSTOMER_BUCKET} --key mithril.tar.gz --acl public-read