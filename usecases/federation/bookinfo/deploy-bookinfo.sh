#!/bin/bash

kubectl apply -f ../../../POC/bookinfo/secrets.yaml

istioctl kube-inject --filename ../../../POC/bookinfo/bookinfo.yaml | kubectl apply -f -

kubectl apply -f ../../../POC/bookinfo/gateway.yaml
