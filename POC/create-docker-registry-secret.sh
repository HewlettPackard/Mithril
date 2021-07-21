#!/bin/bash

HUB_PASSWORD="$(aws ecr get-login-password --region us-east-1)"

kubectl create ns istio-system

kubectl create secret docker-registry secret-registry -n istio-system \
  --docker-server=$HUB\
  --docker-username=AWS \
  --docker-password=$HUB_PASSWORD
  
#copy docker-registry secret to namespace default 
kubectl get secret secret-registry --namespace=istio-system -o yaml | sed 's/namespace: istio-system/namespace: default/g' | kubectl create -f -  