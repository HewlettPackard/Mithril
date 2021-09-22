#!/bin/bash

kubectl apply -f /mithril/POC/secrets.yaml

istioctl kube-inject --filename /mithril/POC/bookinfo.yaml | kubectl apply -f -

kubectl apply -f /mithril/POC/gateway.yaml
