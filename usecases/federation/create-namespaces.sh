#!/bin/bash

set -e

kubectl create ns istio-system
kubectl create ns spire
kubectl create ns spire2
sleep 2
