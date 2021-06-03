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

# Check Envoy proxy secrets:
curl localhost:15000/certs

# Check Envoy proxy configuration:
curl localhost:15000/config_dump

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
