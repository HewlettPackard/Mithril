#!/bin/bash

/home/alexandre/Goland/fork/Mithril/POC/create-kind-cluster.sh
helm install -f /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-server/values.yaml spire-server /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-server/
kubectl rollout status statefulset -n spire spire-server
helm install -f /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-agent/values.yaml spire-agent /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-agent/
kubectl rollout status daemonset -n spire spire-agent
kubectl apply -f /home/alexandre/Goland/fork/Mithril/POC/spire/spiffe-ids.yaml
helm install -f /home/alexandre/Goland/fork/Mithril/POC/base-1.13.4/base/values.yaml base /home/alexandre/Goland/fork/Mithril/POC/base-1.13.4/base/
helm install -f /home/alexandre/Goland/fork/Mithril/POC/istiod-1.13.4/istiod/values.yaml istiod /home/alexandre/Goland/fork/Mithril/POC/istiod-1.13.4/istiod/ -n istio-system
helm install -f /home/alexandre/Goland/fork/Mithril/POC/gateway-1.13.4/gateway/values.yaml ingressgateway /home/alexandre/Goland/fork/Mithril/POC/gateway-1.13.4/gateway/ -n istio-system
kubectl -n istio-system rollout status deployment ingressgateway
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f /home/alexandre/Goland/fork/Mithril/POC/bookinfo/bookinfo.yaml
