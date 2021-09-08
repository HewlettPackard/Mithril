#!/bin/bash

kubectl apply -f secrets.yaml

istioctl kube-inject --filename bookinfo.yaml | kubectl apply -f -

istioctl kube-inject --filename sleep.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
