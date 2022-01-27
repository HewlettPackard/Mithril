#!/bin/bash

if [[ $HUB ]]; then
    echo "Using HUB from environment: $HUB"
    args="$args --set values.global.hub=$HUB"
else
    echo "No HUB set, using default value from istio-config.yaml"
fi

if [[ $TAG ]]; then
    echo "Using TAG from environment: $TAG"
    args="$args --set values.global.tag=$TAG"
else
    echo "No TAG set, using default value from istio-config.yaml"
fi

istioctl install -f istio-config.yaml --skip-confirmation $args
kubectl apply -f auth.yaml
