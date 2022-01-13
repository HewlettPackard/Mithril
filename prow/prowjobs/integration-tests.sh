#!/bin/bash

BUILD_TAG="prow"

cd terraform/integration-tests

for FOLDER in *; do cd ${FOLDER} && terraform init && terraform apply -auto-approve -var "BUILD_TAG"=${BUILD_TAG};
    BUCKET_EXISTS=false
    num_tries=0
    
    while [ $num_tries -lt 500 ];
    do
        aws s3api head-object --bucket mithril-artifacts --key "${BUILD_TAG}/${BUILD_TAG}-${FOLDER}-log.txt" --no-cli-pager 2> /dev/null
        if [ $? -eq 0 ];
            then
                break
            else
                ((num_tries++))
                sleep 1
        fi
    done

    terraform destroy -auto-approve

    cd ..
done
