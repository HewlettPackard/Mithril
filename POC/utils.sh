#!/bin/bash

# Generate Secrets

# Mint SVIDs for workloads
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/details -ttl 8760h -write /tmp/details
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/productpage -ttl 8760h -write /tmp/productpage
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/ratings -ttl 8760h -write /tmp/ratings
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/reviews -ttl 8760h -write /tmp/reviews

cat /tmp/details/svid.pem /tmp/details/bundle.pem > /tmp/details/chain.pem
cat /tmp/productpage/svid.pem /tmp/productpage/bundle.pem > /tmp/productpage/chain.pem
cat /tmp/ratings/svid.pem /tmp/ratings/bundle.pem > /tmp/ratings/chain.pem
cat /tmp/reviews/svid.pem /tmp/reviews/bundle.pem > /tmp/reviews/chain.pem

# Mint SVID for Istio IngressGateway
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account -ttl 8760h -write /tmp/ingress
cat /tmp/ingress/svid.pem /tmp/ingress/bundle.pem > /tmp/ingress/chain.pem

# Convert to base64

# Convert `pem` file to base64 and copy to clipboard, then paste it in the corresponding place in bookinfo/secrets

cat chain.pem | base64 | pbcopy


# Debug proxy using Envoy admin interface

# Log into pod in container istio-proxy
kubectl exec --stdin --tty $POD -c istio-proxy  -- /bin/bash

kubectl exec --stdin --tty $POD -c istio-proxy  -- curl localhost:15000/config_dump

# Check Envoy proxy secrets:
curl localhost:15000/certs

# Check Envoy proxy configuration:
curl localhost:15000/config_dump
kubectl exec --stdin --tty $POD -c istio-proxy  -- curl localhost:15000/config_dump > config.json

# Change logging config to debug:
curl -X POST localhost:15000/logging?level=debug


# Port forward to the first istio-ingressgateway pod
alias igpf='kubectl -n istio-system port-forward $(kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath="{.items[0].metadata.name}") 15000'

# Get the http routes from the port-forwarded ingressgateway pod (requires jq)
alias iroutes='curl --silent http://localhost:15000/config_dump | jq '\''.configs.routes.dynamic_route_configs[].route_config.virtual_hosts[]| {name: .name, domains: .domains, route: .routes[].match.prefix}'\'''

# Get the logs of the first istio-ingressgateway pod
# Shows what happens with incoming requests and possible errors
alias igl='kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath="{.items[0].metadata.name}") --tail=300'

# Get the logs of the first istio-pilot pod
# Shows issues with configurations or connecting to the Envoy proxies
alias ipl='kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=pilot -o=jsonpath="{.items[0].metadata.name}") discovery --tail=300'

# Debug services connections
kubectl run --generator=run-pod/v1 -i --tty busybox-curl --image=radial/busyboxplus:curl --restart=Never -- sh


# istiod dashboard
istioctl dashboard controlz deployment/istiod.istio-system


# SPIRE bundles
## show
kubectl exec --stdin --tty -n spire2 spire-server-0  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock
## set
kubectl exec --stdin --tty -n spire spire-server-0 -c spire-server  -- /opt/spire/bin/spire-server bundle set  -format spiffe -id spiffe://domain.test -socketPath /run/spire/sockets/server.sock

## Mint SVID in domain.test
kubectl exec --stdin --tty -n spire2 spire-server-0  -- /opt/spire/bin/spire-server x509 mint -spiffeID spiffe://domain.test/myservice -socketPath /run/spire/sockets/server.sock

## curl with TLS
curl --cert svid.pem --key key.pem -k -I  https://localhost:7000/productpage
