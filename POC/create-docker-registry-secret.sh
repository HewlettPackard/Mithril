#!/bin/bash

HUB_PASSWORD="$(aws ecr get-login-password --region us-east-1)"

kubectl apply -f istio/istio-namespace.yaml 

kubectl create secret docker-registry secret-registry -n istio-system \
  --docker-server=$HUB\
  --docker-username=AWS \
  --docker-password=$HUB_PASSWORD
  