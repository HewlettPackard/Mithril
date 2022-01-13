#!/bin/bash

export ECR_REGION="us-east-1"
export BUILD_WITH_CONTAINER=0

BUILD_TAG="prow"
ECR_HUB="529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril"

export HUB=${ECR_HUB}
export TAG=${BUILD_TAG}

aws ecr get-login-password --region ${ECR_REGION} | \
    docker login --username AWS --password-stdin ${HUB}

cd istio

dockerd &

go get github.com/spiffe/go-spiffe/v2
go mod tidy 
make push