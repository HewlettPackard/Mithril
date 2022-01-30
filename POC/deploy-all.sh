#!/bin/bash

./create-namespaces.sh
kubectl apply -f ./configmaps.yaml

(cd spire ; ./deploy-spire.sh)

(cd istio ; ./deploy-istio.sh)
(cd bookinfo ; ./deploy-bookinfo.sh)
