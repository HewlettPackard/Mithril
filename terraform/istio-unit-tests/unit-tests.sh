#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt update -y
apt install docker.io awscli -y

aws configure set aws_access_key_id ${access_key}
aws configure set aws_secret_access_key ${secret_access_key}

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${hub}

docker pull ${hub}:${build_tag}

# Tagging for easier use within the docker command below
docker tag ${hub}:${build_tag} mithril-testing:${build_tag}

# Creating kubernetes config to use kubectl inside the container
mkdir -p $HOME/.kube && touch $HOME/.kube/config

# Running usecase and testing it
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c 'echo ${istio_branch} && mkdir tmp && cd tmp && git clone --single-branch --branch ${istio_branch} https://github.com/istio/istio.git &&
cd istio && git apply /mithril/POC/patches/poc.${istio_branch}.patch && go mod tidy && make clean && make init &&
go test -coverprofile coverage.out ./... && 
AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} aws s3 cp coverage.out s3://mithril-artifacts/${build_tag}/ --region us-east-1 &&
AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} aws s3 cp coverage.html s3://mithril-artifacts/${build_tag}/ --region us-east-1 &&
'

cat /var/log/user-data.log >> ${build_tag}-istio-unit-tests-log.txt

aws s3 cp /${build_tag}-istio-unit-tests-log.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1
