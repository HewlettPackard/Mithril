#!/bin/bash

(cd bookinfo ; ./cleanup-bookinfo.sh)
(cd istio ; ./cleanup-istio.sh)
(cd spire ; ./cleanup-spire.sh)
(cd spire2 ; ./cleanup-spire.sh)

