#!/bin/bash

INGRESS_POD=$(kubectl get pod -l istio=ingressgateway-mtls -n istio-system -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward "$INGRESS_POD"  7000:7080 -n istio-system &
