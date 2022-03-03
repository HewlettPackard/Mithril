#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt update -y
apt install docker.io awscli git -y

aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile prow
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile prow
aws configure set region $AWS_DEFAULT_REGION --profile prow

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${hub}

docker pull ${hub}:${build_tag}

# Tagging for easier use within the docker command below
docker tag ${hub}:${build_tag} mithril-testing:${build_tag}

# Creating kubernetes config to use kubectl inside the container
mkdir -p $HOME/.kube && touch $HOME/.kube/config

git clone --single-branch --branch master https://github.com/istio/istio.git /home/istio

# Running usecase and testing it
docker run -i \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
--mount src=/home/istio,target=/mithril/prow,type=bind
bash -c 'cd /mithril/prow 
&& prow/integ-suite-kind.sh test.integration.pilot.kube'