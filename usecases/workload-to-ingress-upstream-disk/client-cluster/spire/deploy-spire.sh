#!/bin/bash

set -e

# Deploy the k8s operator that synchronizes the trust bundle across namespaces
kubectl apply -f /mithril/POC/synator-synchronizer.yaml

# Create the namespace
kubectl apply -f /mithril/POC/spire-namespace.yaml

# Create the k8s-workload-registrar crd, configmap and associated role bindingsspace
kubectl apply \
    -f /mithril/POC/k8s-workload-registrar-crd-cluster-role.yaml \
    -f /mithril/POC/k8s-workload-registrar-crd-configmap.yaml \
    -f /mithril/POC/spiffeid.spiffe.io_spiffeids.yaml

# Create the server’s service account, configmap and associated role bindings
kubectl apply \
    -f /mithril/POC/server-account.yaml \
    -f /mithril/POC/spire-bundle-configmap.yaml \
    -f /mithril/POC/server-cluster-role.yaml

# Deploy the server configmap and statefulset
kubectl apply \
    -f server-configmap.yaml \
    -f server-statefulset.yaml \
    -f /mithril/POC/server-service.yaml

# Configuring and deploying the SPIRE Agent
kubectl apply \
    -f /mithril/POC/agent-account.yaml \
    -f /mithril/POC/agent-cluster-role.yaml

sleep 2

kubectl apply \
    -f /mithril/POC/agent-configmap.yaml \
    -f /mithril/POC/agent-daemonset.yaml


