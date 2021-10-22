#!/bin/bash

kubectl apply -f ../../../../POC/bookinfo/secrets.yaml

istioctl kube-inject --filename ../../../common/workloads/httpbin.yaml | kubectl apply -f -

kubectl apply -f ../../../common/networking/gateway.yaml
