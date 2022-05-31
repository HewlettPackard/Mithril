#!/bin/bash

DIR="../../../POC"

istioctl --filename $DIR/bookinfo/bookinfo.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
