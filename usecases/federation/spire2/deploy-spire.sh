#!/bin/bash

set -e

# Create the namespace
kubectl apply -f spire-namespace.yaml

# Create the server’s service account, configmap and associated role bindings
kubectl apply \
    -f server-account.yaml \
    -f spire-bundle-configmap.yaml \
    -f server-cluster-role.yaml

# Deploy the server configmap and statefulset
kubectl apply \
    -f server-configmap.yaml \
    -f server-statefulset.yaml \
    -f server-service.yaml
