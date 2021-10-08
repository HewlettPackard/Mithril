#!/bin/bash

set -e

# Deploy the k8s operator that synchronizes the trust bundle across namespaces
kubectl apply -f ../../../POC/spire/synator-synchronizer.yaml

# Create the namespace
kubectl apply -f ../../../POC/spire/spire-namespace.yaml

# Create the k8s-workload-registrar crd, configmap and associated role bindingsspace
kubectl apply \
    -f ../../../POC/spire/k8s-workload-registrar-crd-cluster-role.yaml \
    -f ../../../POC/spire/k8s-workload-registrar-crd-configmap.yaml \
    -f ../../../POC/spire/spiffeid.spiffe.io_spiffeids.yaml

# Create the server’s service account, configmap and associated role bindings
kubectl apply \
    -f ../../../POC/spire/server-account.yaml \
    -f ../../../POC/spire/spire-bundle-configmap.yaml \
    -f ../../../POC/spire/server-cluster-role.yaml

# Deploy the server configmap and statefulset
kubectl apply \
    -f server-configmap.yaml \
    -f ../../../POC/spire/server-statefulset.yaml \
    -f ../../../POC/spire/server-service.yaml

# Configuring and deploying the SPIRE Agent
kubectl apply \
    -f ../../../POC/spire/agent-account.yaml \
    -f ../../../POC/spire/agent-cluster-role.yaml

sleep 2

kubectl apply \
    -f ../../../POC/spire/agent-configmap.yaml \
    -f ../../../POC/spire/agent-daemonset.yaml


