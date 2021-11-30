#!/bin/bash

# create all namespaces at the beginning to prevent errors with the bundle sync
../../POC/create-namespaces.sh

kubectl apply -f ../../POC/configmaps.yaml

(cd ../../POC/spire ; ./deploy-spire.sh)
sleep 2
(cd istio ; ./deploy-istio.sh)
(cd workloads ; ./deploy-workloads.sh)
