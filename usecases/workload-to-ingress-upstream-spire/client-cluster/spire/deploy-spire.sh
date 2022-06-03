#!/bin/bash

kubectl apply -k ../../../../POC/spire/

# Deploy the server configmap and statefulset
kubectl apply \
    -f server-configmap.yaml \
    -f server-statefulset.yaml \

# Re-deploy spire-server to reflect configmap update
kubectl delete pod -n spire spire-server-0

# Configuring and deploying nested SPIRE Agent
kubectl apply \
    -f ../../common/spire/agent-nest-account.yaml \
    -f ../../common/spire/agent-nest-cluster-role.yaml

sleep 2

kubectl apply \
    -f agent-nest-configmap.yaml

# Re-deploy spire-agent to reflect configmap update
kubectl delete pod -n spire -l app=spire-agent
