#!/bin/bash

kubectl config use-context kind-kind

kubectl port-forward --address 0.0.0.0 spire-server-0 4001:8443 -n spire &

bundle_server=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/api.sock)

kubectl config use-context kind-kind2

kubectl port-forward --address 0.0.0.0 spire-server-0 4002:8443 -n spire &

bundle_client=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/api.sock)

kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://example.org -socketPath /run/spire/sockets/api.sock <<< "$bundle_server"

kubectl config use-context kind-kind

kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://domain.test -socketPath /run/spire/sockets/api.sock <<< "$bundle_client"