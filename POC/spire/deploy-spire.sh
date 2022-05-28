#!/bin/bash

kubectl apply -k .
kubectl rollout status statefulset -n spire spire-server
kubectl rollout status daemonset -n spire spire-agent

kubectl apply -f spiffe-ids.yaml
