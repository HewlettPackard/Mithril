#!/bin/bash

istioctl kube-inject --filename ../../../common/workloads/httpbin.yaml | kubectl apply -f -

kubectl apply -f ../../../common/networking/gateway.yaml