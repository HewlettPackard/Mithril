#!/bin/bash

kubectl apply -f /mithril/POC/bookinfo/secrets.yaml

istioctl kube-inject --filename /mithril/POC/bookinfo/bookinfo.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
