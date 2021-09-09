#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt update -y
apt install docker.io awscli -y

aws configure set aws_access_key_id ${access_key}
aws configure set aws_secret_access_key ${secret_access_key}

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${hub}

echo "===== " $${PWD} " ====="

docker pull ${hub}:${build_tag}

# Tagging for easier use within the docker command below
docker tag ${hub}:${build_tag} mithril-testing:${build_tag}

# Creating kubernetes config to use kubectl inside the container
mkdir -p $HOME/.kube && touch $HOME/.kube/config

# Creating kind cluster
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
/mithril/POC/create-kind-cluster.sh

# Creating Docker secrets for ECR images
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c "HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} /mithril/POC/create-docker-registry-secret.sh"

# Deploying the PoC
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c "cd /mithril/POC && TAG=stable_20210909 HUB=${hub} ./deploy-all.sh"

# Port Forwarding the POD
docker run -i -d --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c 'INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}") \
&& kubectl port-forward "$INGRESS_POD"  8000:8080 -n istio-system'

# Waiting for POD to be ready
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c 'kubectl rollout status deployment productpage-v1'

# Test simple_bookinfo_test
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c "cd /mithril/e2e && go test -v simple_bookinfo_test.go > ${build_tag}_simple_bookinfo_test.txt"

# Copying response to S3 bucket
aws s3 cp /${build_tag}_simple_bookinfo_test.txt s3://mithril-artifacts/ --region us-east-1

# Generate log files
cp /var/log/user-data.log ${build_tag}_log.txt

echo "===== " $${PWD} " =====" >> ${build_tag}.txt

# Copying log to S3 bucket
aws s3 cp /${build_tag}_log.txt s3://mithril-artifacts/ --region us-east-1