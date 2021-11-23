#!/bin/bash

istioctl kube-inject --filename ../../../common/workloads/sleep.yaml | kubectl apply -f -

kubectl apply -f ../../../common/networking/service-entry.yaml
