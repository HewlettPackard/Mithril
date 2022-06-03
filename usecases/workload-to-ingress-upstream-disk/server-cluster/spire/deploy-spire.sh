#!/bin/bash

kubectl apply -k ../../../../POC/spire/

# Deploy the server configmap and statefulset
kubectl apply \
    -f ../../common/spire/server-configmap.yaml \
    -f ../../common/spire/server-statefulset.yaml \
