#!/bin/bash

# create all namespaces at the beginning to prevent errors with the bundle sync
./create-namespaces.sh

(cd spire ; ./deploy-spire.sh)
sleep 2
(cd istio ; ./deploy-istio.sh)
(cd bookinfo ; ./deploy-bookinfo.sh)
