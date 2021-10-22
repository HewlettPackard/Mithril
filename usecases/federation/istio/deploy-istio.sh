#!/bin/bash

echo "Deploying Istio..."

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

DIR="../../../POC"

if [[ "$1" ]]; then
    DIR=$1
fi

kubectl create ns istio-system
sleep 2
kubectl apply -f $DIR/istio/secrets.yaml
istioctl install -f istio-config.yaml --skip-confirmation $args
kubectl apply -f $DIR/istio/auth.yaml
