#!/bin/bash

set -e

# Create the namespace
kubectl apply -f spire-namespace.yaml

# Create the k8s-workload-registrar crd, configmap and associated role bindingsspace
kubectl apply \
    -f k8s-workload-registrar-crd-cluster-role.yaml \
    -f k8s-workload-registrar-crd-configmap.yaml \
    -f spiffeid.spiffe.io_spiffeids.yaml

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

# Configuring and deploying the SPIRE Agent
kubectl apply \
    -f agent-account.yaml \
    -f agent-cluster-role.yaml

sleep 2

kubectl apply \
    -f agent-configmap.yaml \
    -f agent-daemonset.yaml


