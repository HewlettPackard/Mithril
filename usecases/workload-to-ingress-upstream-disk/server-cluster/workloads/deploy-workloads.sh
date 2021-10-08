#!/bin/bash

kubectl apply -f /mithril/POC/bookinfo/secrets.yaml

istioctl kube-inject --filename httpbin.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
