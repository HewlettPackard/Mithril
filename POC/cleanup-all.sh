#!/bin/bash

(cd bookinfo ; sh cleanup-bookinfo.sh)
(cd istio ; sh cleanup-istio.sh)
(cd spire ; sh cleanup-spire.sh)

