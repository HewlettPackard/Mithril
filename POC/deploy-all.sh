#!/bin/bash

(cd spire ; ./deploy-spire.sh)
sleep 2
(cd istio ; ./deploy-istio.sh)
(cd bookinfo ; ./deploy-bookinfo.sh)
