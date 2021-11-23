#!/bin/bash

istioctl kube-inject --filename sleep.yaml | kubectl apply -f -

kubectl apply -f external-mtls-direct.yaml

kubectl apply -f external-mtls-egress.yaml
