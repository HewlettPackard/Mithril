#!/bin/bash

# create all namespaces at the beginning to prevent errors with the bundle sync
../../../POC/create-namespaces.sh

kubectl create configmap spire-bundle-nest --from-file ../root-cert.pem --namespace="spire"
kubectl create configmap agent-nesteda-cert --from-file ../nestedA/agent-nestedA.crt.pem --namespace="spire"
kubectl create configmap agent-nesteda-key --from-file ../nestedA/agent-nestedA.key.pem --namespace="spire"

(cd spire ; ./deploy-spire.sh)

(cd ../../../POC/istio ; ./deploy-istio.sh)
(cd workloads ; ./deploy-workloads.sh)
