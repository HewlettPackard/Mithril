#!/bin/bash

# create all namespaces at the beginning to prevent errors with the bundle sync
./create-namespaces.sh

kubectl create configmap dummy-ca-crt --from-file ./dummy_upstream_ca.crt --namespace="spire"
kubectl create configmap dummy-ca-key --from-file ./dummy_upstream_ca.key --namespace="spire"

(cd spire ; ./deploy-spire.sh)
sleep 2
(cd istio ; ./deploy-istio.sh)
(cd bookinfo ; ./deploy-bookinfo.sh)
