#!/bin/bash

# create all namespaces at the beginning to prevent errors with the bundle sync
../../../POC/create-namespaces.sh

kubectl apply -f ../../../POC/configmaps.yaml

kubectl create configmap upstream-ca-crt --from-file ../../common/spire/certs/upstream-ca.pem --namespace="spire"
kubectl create configmap upstream-ca-key --from-file ../../common/spire/keys/upstream-ca.key.pem --namespace="spire"

(cd spire ; ./deploy-spire.sh)
sleep 2
(cd istio ; ./deploy-istio.sh)
(cd workloads ; ./deploy-workloads.sh)
