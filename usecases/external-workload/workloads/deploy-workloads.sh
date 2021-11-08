#!/bin/bash

kubectl apply -f ../../../POC/bookinfo/secrets.yaml

istioctl kube-inject --filename sleep.yaml | kubectl apply -f -

kubectl apply -f external-mtls-direct.yaml

kubectl apply -f external-mtls-egress.yaml
