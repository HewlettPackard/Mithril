#!/bin/bash

./create-namespaces.sh
kubectl apply -f ./configmaps.yaml

kubectl apply -k spire/controller
kubectl rollout status statefulset -n spire spire-server
kubectl rollout status daemonset -n spire spire-agent
kubectl apply -f spire/controller/spiffe-ids.yaml
#kubectl apply -f spire/controller/ingress-gateway.yaml
#(cd spire ; ./deploy-spire.sh)

#(cd istio ; ./deploy-istio.sh)
kubectl apply -f core.yaml
kubectl apply -f pilot.yaml
kubectl apply -f ingress.yaml
(cd bookinfo ; ./deploy-bookinfo.sh)
