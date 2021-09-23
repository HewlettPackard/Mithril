#!/bin/bash

set -e

# Deploy the k8s operator that synchronizes the trust bundle across namespaces
kubectl apply -f /mithril/POC/spire/synator-synchronizer.yaml

# Create the namespace
kubectl apply -f /mithril/POC/spire/spire-namespace.yaml

# Create the k8s-workload-registrar crd, configmap and associated role bindingsspace
kubectl apply \
    -f /mithril/POC/spire/k8s-workload-registrar-crd-cluster-role.yaml \
    -f /mithril/POC/spire/k8s-workload-registrar-crd-configmap.yaml \
    -f /mithril/POC/spire/spiffeid.spiffe.io_spiffeids.yaml

# Create the server’s service account, configmap and associated role bindings
kubectl apply \
    -f /mithril/POC/spire/server-account.yaml \
    -f /mithril/POC/spire/spire-bundle-configmap.yaml \
    -f /mithril/POC/spire/server-cluster-role.yaml

# Deploy the server configmap and statefulset
kubectl apply \
    -f server-configmap.yaml \
    -f server-statefulset.yaml \
    -f /mithril/POC/spire/server-service.yaml

# Configuring and deploying the SPIRE Agent
kubectl apply \
    -f /mithril/POC/spire/agent-account.yaml \
    -f /mithril/POC/spire/agent-cluster-role.yaml

sleep 2

kubectl apply \
    -f /mithril/POC/spire/agent-configmap.yaml \
    -f /mithril/POC/spire/agent-daemonset.yaml


