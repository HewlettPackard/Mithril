#!/bin/bash

(cd spire ; sh deploy-spire.sh)
sleep 2
(cd istio ; sh deploy-istio.sh)
(cd bookinfo ; sh deploy-bookinfo.sh)
