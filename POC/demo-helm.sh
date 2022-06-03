#!/bin/bash

DIR="../mithrilctl/helm"

./create-kind-cluster.sh

helm install -f "$DIR"/spire/spire-server/values.yaml spire-server "$DIR"/spire/spire-server/
kubectl rollout status statefulset -n spire spire-server

helm install -f "$DIR"/spire/spire-agent/values.yaml spire-agent "$DIR"/spire/spire-agent/
kubectl rollout status daemonset -n spire spire-agent

kubectl apply -f "$DIR"/spire/spiffe-ids.yaml

helm install -f "$DIR"/istio/base-1.13.4/base/values.yaml base "$DIR"/istio/base-1.13.4/base/
helm install -f "$DIR"/istio/istiod-1.13.4/istiod/values.yaml istiod "$DIR"/istio/istiod-1.13.4/istiod/ -n istio-system
helm install -f "$DIR"/istio/gateway-1.13.4/gateway/values.yaml ingressgateway "$DIR"/istio/gateway-1.13.4/gateway/ -n istio-system
kubectl -n istio-system rollout status deployment ingressgateway

kubectl apply -f bookinfo/bookinfo.yaml
