#!/bin/bash

set -e

# Parameterizing DIR folder in order to get demo-script running
DIR="../../.."

if [[ "$1" ]]; then
    DIR=$1
fi

# Deploy the k8s operator that synchronizes the trust bundle across namespaces
kubectl apply -f $DIR/POC/spire/synator-synchronizer.yaml

# Create the namespace
kubectl apply -f $DIR/POC/spire/spire-namespace.yaml

# Create the k8s-workload-registrar crd, configmap and associated role bindingsspace
kubectl apply \
    -f $DIR/POC/spire/k8s-workload-registrar-crd-cluster-role.yaml \
    -f $DIR/POC/spire/k8s-workload-registrar-crd-configmap.yaml \
    -f $DIR/POC/spire/spiffeid.spiffe.io_spiffeids.yaml

# Create the server’s service account, configmap and associated role bindings
kubectl apply \
    -f $DIR/POC/spire/server-account.yaml \
    -f $DIR/POC/spire/spire-bundle-configmap.yaml \
    -f $DIR/POC/spire/server-cluster-role.yaml

# Deploy the server configmap and statefulset
kubectl apply \
    -f server-configmap.yaml \
    -f $DIR/POC/spire/server-statefulset.yaml \
    -f $DIR/POC/spire/server-service.yaml

# Configuring and deploying the SPIRE Agent
kubectl apply \
    -f $DIR/POC/spire/agent-account.yaml \
    -f $DIR/POC/spire/agent-cluster-role.yaml

sleep 2

kubectl apply \
    -f $DIR/POC/spire/agent-configmap.yaml \
    -f $DIR/POC/spire/agent-daemonset.yaml
    