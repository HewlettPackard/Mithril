#!/bin/bash

INGRESS_POD=$(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --address 0.0.0.0 "$INGRESS_POD"  8000:8080 -n istio-system &
