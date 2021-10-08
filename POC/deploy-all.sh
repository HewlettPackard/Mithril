#!/bin/bash

# create all namespaces at the beginning to prevent errors with the bundle sync
./create-namespaces.sh

(cd spire ; ./deploy-spire.sh)

(cd istio ; ./deploy-istio.sh)
(cd bookinfo ; ./deploy-bookinfo.sh)
