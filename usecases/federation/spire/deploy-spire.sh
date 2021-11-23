#!/bin/bash

set -e

# Parameterizing DIR folder in order to get demo-script running
DIR="../../../POC"

if [[ "$1" ]]; then
    DIR=$1
fi

# Create the k8s-workload-registrar crd, configmap and associated role bindingsspace
kubectl apply \
    -f $DIR/spire/k8s-workload-registrar-crd-cluster-role.yaml \
    -f $DIR/spire/k8s-workload-registrar-crd-configmap.yaml \
    -f $DIR/spire/spiffeid.spiffe.io_spiffeids.yaml

# Create the server’s service account, configmap and associated role bindings
kubectl apply \
    -f $DIR/spire/server-account.yaml \
    -f $DIR/spire/spire-bundle-configmap.yaml \
    -f $DIR/spire/server-cluster-role.yaml

# Deploy the server configmap and statefulset
kubectl apply \
    -f server-configmap.yaml \
    -f $DIR/spire/server-statefulset.yaml \
    -f $DIR/spire/server-service.yaml

# Configuring and deploying the SPIRE Agent
kubectl apply \
    -f $DIR/spire/agent-account.yaml \
    -f $DIR/spire/agent-cluster-role.yaml

sleep 2

kubectl apply \
    -f agent-configmap.yaml \
    -f $DIR/spire/agent-daemonset.yaml
    