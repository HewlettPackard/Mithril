#!/bin/bash
set -x

folder=$(dirname "$0")
pushd "$folder" || exit

# create all namespaces at the beginning to prevent errors with the bundle sync
./create-namespaces.sh

(cd spire2 ; ./deploy-spire.sh)
(cd spire ; ./deploy-spire.sh)

# wait until spire2 is ready
kubectl rollout status statefulset -n spire2 spire-server
# echo bundle from spire2 (domain.test)
bundle=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire2  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

# wait until spire is ready
kubectl rollout status statefulset -n spire spire-server
# set domain.test bundle to spire
kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://domain.test -socketPath /run/spire/sockets/server.sock <<< "$bundle"

(cd istio ; ./deploy-istio.sh)
(cd bookinfo ; ./deploy-bookinfo.sh)
