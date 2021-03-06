#!/bin/bash

# create all namespaces at the beginning to prevent errors with the bundle sync
../../../POC/create-namespaces.sh

kubectl apply -f ../../../POC/configmaps.yaml

kubectl create configmap spire-bundle-nest --from-file ../root-cert.pem --namespace="spire"
kubectl create configmap agent-nestedb-cert --from-file ../nestedB/agent-nestedB.crt.pem --namespace="spire"
kubectl create configmap agent-nestedb-key --from-file ../nestedB/agent-nestedB.key.pem --namespace="spire"

(cd spire ; ./deploy-spire.sh)

(cd ../../../POC/istio ; ./deploy-istio.sh)
(cd workloads ; ./deploy-workloads.sh)
