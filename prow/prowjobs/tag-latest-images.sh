#!/bin/bash

export ECR_REGION="us-east-1"
export ECR_REGISTRY="529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril"

#TODO: set image tags dinamicaly
BUILD_TAG="10-01-2022-release-1.12-master-679014a"
ISTIO_IMAGES=("install-cni" "operator" "istioctl" "app_sidecar_centos_7" "app_sidecar_centos_8" "app_sidecar_debian_10" "app_sidecar_debian_9" "app_sidecar_ubuntu_focal" "app_sidecar_ubuntu_bionic" "app_sidecar_ubuntu_xenial" "app" "proxyv2" "pilot")

aws ecr get-login-password --region ${ECR_REGION} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}

dockerd & 

if (! docker stats --no-stream ); then

    while (! docker stats --no-stream ); do
        echo "Waiting for Docker to launch..."
        sleep 1
    done

    for ISTIO_IMAGE in "${ISTIO_IMAGES[@]}";
        do 
            echo $ECR_REGISTRY/$ISTIO_IMAGE:$BUILD_TAG
            docker pull $ECR_REGISTRY/$ISTIO_IMAGE:$BUILD_TAG
        done

    docker images "${ECR_REGISTRY}/*" --format "{{.ID}} {{.Repository}}" | while read line; do
        docker tag $line":latest-test"
        pieces=(\\$line)
        docker push ${pieces[1]}":latest-test"
    done
fi

pkill -f dockerd