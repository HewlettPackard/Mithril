#!/bin/bash

aws configure set aws_access_key_id AKIAXWLCWD5JU7PMBB4M
aws configure set aws_secret_access_key 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

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril

./create-kind-cluster.sh

HUB="529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril" AWS_ACCESS_KEY_ID="AKIAXWLCWD5JU7PMBB4M" AWS_SECRET_ACCESS_KEY="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"

./create-docker-registry-secret.sh

./create-namespaces.sh

TAG="stable_20210909" ./deploy-all.sh
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

