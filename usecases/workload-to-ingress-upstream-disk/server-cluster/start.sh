#!/bin/bash

./create-kind-cluster.sh

HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} ./create-docker-registry-secret.sh

TAG=stable_20210909 HUB=${hub} ./deploy-all.sh

echo "TAG=$TAG HUB=$HUB"

INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")

echo $INGRESS_POD

kubectl port-forward "$INGRESS_POD"  8000:8080 -n istio-system

kubectl rollout status deployment productpage-v1 && kubectl get pods -A