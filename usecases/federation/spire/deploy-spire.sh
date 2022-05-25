#!/bin/bash

set -e

# Parameterizing DIR folder in order to get demo-script running
DIR="../../../POC"

if [[ "$1" ]]; then
    DIR=$1
fi

kubectl apply -k ../../../POC/spire/

kubectl apply -f server-configmap.yaml

# Re-deploy spire-server to reflect configmap update
kubectl delete pod -n spire spire-server-0
sleep 2

kubectl apply -f agent-configmap.yaml

# Re-deploy spire-agent to reflect configmap update
kubectl delete pod -n spire -l app=spire-agent
