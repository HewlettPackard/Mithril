#!/bin/bash

find . -type f -iname "*.sh" -exec chmod +x {} \;

./create-kind-cluster.sh

HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key}

echo ${hub} ${access_key} ${secret_access_key}
echo ${HUB} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY}

./create-docker-registry-secret.sh

TAG=${build_tag} HUB=${hub} ./deploy-all.sh

INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")

kubectl port-forward "$INGRESS_POD"  8000:8080 -n istio-system

kubectl rollout status deployment productpage-v1

cd /mithril/e2e

go test -v e2e -run TestSimpleBookinfo > ${build_tag}-${usecase}-result.txt

AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} aws s3 cp ${build_tag}-${usecase}-result.txt s3://mithril-artifacts/${build_tag}/ --region us-east-1