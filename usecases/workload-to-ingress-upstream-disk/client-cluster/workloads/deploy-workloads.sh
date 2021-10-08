#!/bin/bash

kubectl apply -f secrets.yaml

istioctl kube-inject --filename sleep.yaml | kubectl apply -f -

kubectl apply -f service-entry.yaml
