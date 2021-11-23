#!/bin/bash

kubectl delete CustomResourceDefinition spiffeids.spiffeid.spiffe.io
kubectl delete -f k8s-workload-registrar-crd-configmap.yaml -f k8s-workload-registrar-crd-cluster-role.yaml  
kubectl delete clusterrole spire-server-trust-role spire-agent-cluster-role
kubectl delete clusterrolebinding spire-server-trust-role-binding spire-agent-cluster-role-binding
kubectl delete namespace spire
