#!/bin/bash

./create-kind-cluster.sh

HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} ./create-docker-registry-secret.sh

TAG=stable_20210909 HUB=${hub} ./deploy-all.sh

echo "TAG=$TAG HUB=$HUB"

kubectl wait pod --for=condition=Ready -l app=sleep

kubectl rollout status deployment sleep

CLIENT_POD=$(kubectl get pod -l app=sleep -n default -o jsonpath="{.items[0].metadata.name}")

echo $CLIENT_POD

kubectl exec -i -t pod/$CLIENT_POD -c sleep -- /bin/sh -c "curl -sSLk --cert /sleep-certs/sleep-svid.pem --key /sleep-certs/sleep-key.pem --cacert /sleep-certs/root-cert.pem https://${HOST_IP}:8000/productpage"