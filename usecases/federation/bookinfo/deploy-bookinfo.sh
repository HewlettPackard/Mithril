#!/bin/bash

DIR=$(cd ../../../POC; echo $PWD)

istioctl --filename $DIR/bookinfo/bookinfo.yaml | kubectl apply -f -

kubectl apply -f gateway.yaml
