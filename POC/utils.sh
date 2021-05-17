#!/bin/bash

# Generate Secrets

# Mint SVIDs
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/details -ttl 8760h -write /tmp/details
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/productpage -ttl 8760h -write /tmp/productpage
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/ratings -ttl 8760h -write /tmp/ratings
./spire-server x509 mint -spiffeID spiffe://cluster.local/ns/default/sa/reviews -ttl 8760h -write /tmp/reviews

cat /tmp/details/svid.pem /tmp/details/bundle.pem > /tmp/details/chain.pem
cat /tmp/productpage/svid.pem /tmp/productpage/bundle.pem > /tmp/productpage/chain.pem
cat /tmp/ratings/svid.pem /tmp/ratings/bundle.pem > /tmp/ratings/chain.pem
cat /tmp/reviews/svid.pem /tmp/reviews/bundle.pem > /tmp/reviews/chain.pem

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


