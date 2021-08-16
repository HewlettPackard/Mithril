#!/bin/bash -xe

sudo apt update -y
sudo apt install docker.io awscli -y

sudo usermod -aG docker $USER

newgrp docker

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $HUB

docker pull $HUB:$TAG

# Tagging for easier use within the docker command below
docker tag $HUB:$TAG mithril-testing:$TAG

# Creating kubernetes config to use kubectl inside the container
mkdir -p $HOME/.kube && touch $HOME/.kube/config

# Creating kind cluster
docker run --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "$HOME/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:$TAG \
/mithril/POC/create-kind-cluster.sh

# Creating Docker secrets for ECR images
docker run --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "$HOME/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:$TAG \
bash -c "HUB=$HUB AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY /mithril/POC/create-docker-registry-secret.sh"

# Deploying the PoC
docker run --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "$HOME/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:$TAG \
bash -c "cd /mithril/POC && TAG=$TAG HUB=$HUB ./deploy-all.sh"

sudo docker run -d --rm \
 -v "/var/run/docker.sock:/var/run/docker.sock:rw" \
 -v "$HOME/.kube/config:/root/.kube/config:rw" \
 --network host mithril-testing:latest \
 bash -c 'INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}") \
 && kubectl port-forward "$INGRESS_POD"  8000:8080 -n istio-system'
 