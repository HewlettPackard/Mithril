#!/bin/bash

./create-namespaces.sh
kubectl apply -f ./configmaps.yaml

#kubectl apply -f spire/controller/istiod.yaml
#kubectl apply -k spire/controller
#(cd spire ; ./deploy-spire.sh)

(cd istio ; ./deploy-istio.sh)
#kubectl apply -f pilot.yaml
#(cd bookinfo ; ./deploy-bookinfo.sh)
