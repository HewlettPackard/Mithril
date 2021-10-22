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
bash -c 'cd /mithril/usecases && find . -type f -iname "*.sh" -exec chmod +x {} \; && cd ${usecase} && /mithril/POC/create-kind-cluster.sh &&
HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} /mithril/POC/create-docker-registry-secret.sh &&
kubectl create ns spire && TAG=${build_tag} HUB=${hub} ./deploy-all.sh &&
kubectl rollout status deployment sleep &&
SPIRE_AGENT_POD=$(kubectl get pod -l app=spire-agent -n spire -o jsonpath="{.items[0].metadata.name}") &&
kubectl exec -n spire $SPIRE_AGENT_POD -c spire-agent -- /opt/spire/bin/spire-agent api fetch -write /tmp/ -socketPath /run/spire/sockets/agent.sock &&
kubectl exec -n spire $SPIRE_AGENT_POD -c spire-agent -- cat /tmp/svid.pem > svid.pem &&
kubectl exec -n spire $SPIRE_AGENT_POD -c spire-agent -- cat /tmp/svid.key > svid.key &&
kubectl exec -n spire $SPIRE_AGENT_POD -c spire-agent -- cat /tmp/bundle.pem > bundle.pem &&
go run tls-server.go & &&
CLIENT_POD=$(kubectl get pod -l app=sleep -n default -o jsonpath="{.items[0].metadata.name}") &&
kubectl exec -i -t pod/$CLIENT_POD -c sleep -- /bin/sh -c "curl -v example.org 2>&1 | tee /tmp/${usecase}_test_response.txt" &&
cd /mithril/e2e/${usecase} && touch ${build_tag}-${usecase}-result.txt && go test -v e2e -run TestExternalWorkload 2>&1 | tee ${build_tag}-${usecase}-result.txt &&
AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} aws s3 cp ${build_tag}-${usecase}-result.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1'

cat /var/log/user-data.log >> ${build_tag}-${usecase}-log.txt

aws s3 cp /${build_tag}-${usecase}-log.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1