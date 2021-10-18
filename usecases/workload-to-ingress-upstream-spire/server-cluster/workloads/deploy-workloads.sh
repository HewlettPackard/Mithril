#!/bin/bash

kubectl apply -f ../../../../POC/bookinfo/secrets.yaml

istioctl kube-inject --filename httpbin.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
