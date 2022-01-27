#!/bin/bash

kubectl delete clusterrole spire-server-trust-role
kubectl delete clusterrolebinding spire-server-trust-role-binding
kubectl delete namespace spire2
