#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt update -y
apt install docker.io awscli -y

echo "===== workload-to-ingress-upstream-disk ====="

echo "hub" ${hub}
echo "build_tag" ${build_tag}
echo "aws_access_key_id" ${access_key}
echo "aws_secret_access_key" ${secret_access_key}

aws configure set aws_access_key_id ${access_key}
aws configure set aws_secret_access_key ${secret_access_key}

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${hub}

docker pull ${hub}:${build_tag}

# Tagging for easier use within the docker command below
docker tag ${hub}:${build_tag} mithril-testing:${build_tag}

# Creating kubernetes config to use kubectl inside the container
mkdir -p $HOME/.kube && touch $HOME/.kube/config

#aws s3api head-object --bucket mithril-artifacts --key "${build_tag}_log.txt" --no-cli-pager
#if [ $? -eq 0 ];
#  then
#    aws s3 cp "s3://mithril-artifacts/${build_tag}_log.txt" .
#    echo "===== workload-to-ingress-upstream-disk =====" >> ${build_tag}_log.txt
#  else
#    echo "===== workload-to-ingress-upstream-disk =====" >> ${build_tag}_log.txt
#fi

#echo "===== workload-to-ingress-upstream-disk =====" >> workload-to-ingress-upstream-disk_${build_tag}.txt

HOST_IP=$(hostname -I | awk '{print $1}')
echo $$HOST_IP

# Creating kind cluster for the server
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${build_tag} \
bash -c 'cd /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster &&
find . -type f -iname "*.sh" -exec chmod +x {} \; && ./start.sh'

## Creating kind cluster for the server
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'cd /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster && echo DEPLOYING CLIENT CLUSTER && . ./start.sh &&
#echo DEPLOYING CLIENT CLUSTER && cd /mithril/usecases/workload-to-ingress-upstream-disk/client-cluster && . ./start.sh'

## Creating kind cluster for the server
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'cd /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster && ./create-kind-cluster.sh &&
#HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} ./create-docker-registry-secret.sh &&
#TAG=stable_20210909 HUB=${hub} ./deploy-all.sh &&
#INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}") &&
#kubectl port-forward "$INGRESS_POD" 8000:8080 -n istio-system &&
#kubectl rollout status deployment productpage-v1 && kubectl get pods -A' >> ${build_tag}_log.txt
#
## Creating kind cluster for the client
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'cd /mithril/usecases/workload-to-ingress-upstream-disk/client-cluster && ./create-kind-cluster.sh &&
#HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} ./create-docker-registry-secret.sh &&
#TAG=stable_20210909 HUB=${hub} ./deploy-all.sh &&
#kubectl rollout status deployment sleep && kubectl get pods -A'
#
## Creating kind cluster for the client
#CLIENT_POD=$(docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'kubectl get pod -l app=sleep -n default -o jsonpath="{.items[0].metadata.name}"')
#
#echo $$CLIENT_POD
#
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'kubectl exec -i -t pod/$CLIENT_POD -c sleep -- /bin/sh -c "curl -sSLk --cert /sleep-certs/sleep-svid.pem --key /sleep-certs/sleep-key.pem --cacert /sleep-certs/root-cert.pem https://$${HOST_IP}:8000/productpage"'

## Creating Docker secrets for ECR images
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c "HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} /mithril/POC/create-docker-registry-secret.sh"
#
## Deploying the PoC
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c "cd /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster && TAG=${build_tag} HUB=${hub} ./deploy-all.sh"
#
## Port Forwarding the POD
#docker run -i -d --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}") \
#&& kubectl port-forward "$INGRESS_POD"  8000:8080 -n istio-system'
#
## Waiting for POD to be ready
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'kubectl rollout status deployment productpage-v1'
#
#HOST_IP=$(hostname -I | awk '{print $1}')
#
## Request to productpage workload
#curl localhost:8000/productpage > ${build_tag}.txt
#
## Creating kind cluster for the client
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c "/mithril/usecases/workload-to-ingress-upstream-disk/client-cluster/create-kind-cluster.sh"
#
## Deploying the PoC
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c "cd /mithril/usecases/workload-to-ingress-upstream-disk/client-cluster && TAG=${build_tag} HUB=${hub} ./deploy-all.sh"
#
## Waiting for POD to be ready
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'kubectl rollout status deployment sleep'
#
#CLIENT_POD=$(kubectl get pod -l app=sleep -n default -o jsonpath="{.items[0].metadata.name}")
#
#echo $${HOST_IP}
##echo $${HOST_IP}
#
#
#kubectl exec -i -t pod/$CLIENT_POD -c sleep -- /bin/sh -c "curl -sSLk --cert /sleep-certs/sleep-svid.pem --key /sleep-certs/sleep-key.pem --cacert /sleep-certs/root-cert.pem https://$${HOST_IP}:8000/productpage"
#
## Copying response to S3 bucket
#aws s3 cp /${build_tag}.txt s3://mithril-artifacts/ --region us-east-1
#
## Test simple_bookinfo_test
#docker run -i --rm \
#-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
#-v "/.kube/config:/root/.kube/config:rw" \
#--network host mithril-testing:${build_tag} \
#bash -c 'cd /mithril/e2e && go test -v workload_to_ingress_upstream_disk_test.go > > ${build_tag}_workload_to_ingress_upstream_disk_test.txt'

# Generate log files
#cat /var/log/user-data.log >> workload-to-ingress-upstream-disk_${build_tag}.txt
cat /var/log/user-data.log >> ${build_tag}_${usecase}_log.txt

cat /var/log/user-data.log >> ${build_tag}_${usecase}_result.txt

# Copying log to S3 bucket
aws s3 cp /${build_tag}_${usecase}_log.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1

aws s3 cp /${build_tag}_${usecase}_result.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1