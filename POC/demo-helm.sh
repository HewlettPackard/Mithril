#!/bin/bash

DIR="../mithrilctl/helm"

./create-kind-cluster.sh
kubectl config use-context kind-kind

helm upgrade --install -f "$DIR"/spire/spire-server/values.yaml spire-server "$DIR"/spire/spire-server/
kubectl rollout status statefulset -n spire spire-server

helm upgrade --install -f "$DIR"/spire/spire-agent/values.yaml spire-agent "$DIR"/spire/spire-agent/
kubectl rollout status daemonset -n spire spire-agent

helm upgrade --install -f "$DIR"/istio/base-1.14.1/base/values.yaml base "$DIR"/istio/base-1.14.1/base/
helm upgrade --install -f "$DIR"/istio/istiod-1.14.1/istiod/values.yaml istiod "$DIR"/istio/istiod-1.14.1/istiod/ -n istio-system
helm upgrade --install -f "$DIR"/istio/gateway-1.14.1/gateway/values.yaml ingressgateway "$DIR"/istio/gateway-1.14.1/gateway/ -n istio-system

kubectl -n istio-system rollout status deployment ingressgateway

kubectl apply -f bookinfo/bookinfo.yaml
