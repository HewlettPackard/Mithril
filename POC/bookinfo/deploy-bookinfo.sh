#!/bin/bash

istioctl kube-inject --injectConfigFile /home/alexandre/Goland/fork/Mithril/POC/injection/inject-config.yaml \
  --meshConfigFile /home/alexandre/Goland/fork/Mithril/POC/injection/mesh-config.yaml \
  --valuesFile /home/alexandre/Goland/fork/Mithril/POC/injection/inject-values.yaml \
  --filename bookinfo.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
