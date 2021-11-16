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
docker run -i \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c 'set -x &&
export HUB=${hub} &&
export TAG=${build_tag} &&
export AWS_ACCESS_KEY_ID=${access_key} &&
export AWS_SECRET_ACCESS_KEY=${secret_access_key} &&
/mithril/POC/create-kind-cluster.sh &&
/mithril/POC/create-docker-registry-secret.sh &&
cd /mithril/usecases/federation &&
./deploy-all.sh &&
kubectl wait pod --for=condition=Ready -l app=productpage --timeout=-1s &&
kubectl wait pod --for=condition=Ready -l app=details --timeout=-1s &&
kubectl wait pod --for=condition=Ready -l app=reviews --timeout=-1s &&
kubectl wait pod --for=condition=Ready -l app=ratings --timeout=-1s &&
echo "Deployment done!" &&
/mithril/usecases/federation/forward-secure-port.sh &&
cd /mithril/e2e && go test -v e2e -run TestFederation 2>&1 | tee ${build_tag}-${usecase}-result.txt &&
aws s3 cp ${build_tag}-${usecase}-result.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1 &&
echo "Testing done!"'

cat /var/log/user-data.log >> ${build_tag}-${usecase}-log.txt

aws s3 cp /${build_tag}-${usecase}-log.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1
