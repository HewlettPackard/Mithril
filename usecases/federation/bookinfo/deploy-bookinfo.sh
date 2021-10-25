#!/bin/bash

DIR="../../../POC"

if [[ "$1" ]]; then
    DIR=$1
fi

kubectl apply -f $DIR/bookinfo/secrets.yaml

istioctl kube-inject --filename $DIR/bookinfo/bookinfo.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
