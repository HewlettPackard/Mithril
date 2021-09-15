#!/bin/bash

./create-kind-cluster.sh

#HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key}

echo "HUB=${hub}" "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"

./create-docker-registry-secret.sh

./create-namespaces.sh

TAG="stable_20210909" HUB=${hub} ./deploy-all.sh
#
echo "TAG=$TAG HUB=$HUB"
#
kubectl wait pod --for=condition=Ready -l app=istio-ingressgateway -n istio-system
kubectl wait pod --for=condition=Ready -l app=productpage
#
kubectl rollout status deployment productpage-v1 -n default
kubectl rollout status deployment istio-ingressgateway -n istio-system
#
INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
#
echo $INGRESS_POD
#
kubectl port-forward "$INGRESS_POD"  8000:8080 -n istio-system

