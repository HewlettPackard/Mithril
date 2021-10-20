# Usecases

1. [Connecting two workloads from different Mithril clusters using external disk Spire CA](https://hpe-my.sharepoint.com/:w:/p/alexandre_alvino/EWfvvyHlkfhLtoSRxNu2IFMBTh751hcvejO6oZmwHFQ8pw?e=uM34vG)

2. [Connecting Mithril to an external workload, through Egress or directly through istio-proxy (sidecar)](https://hpe-my.sharepoint.com/:w:/p/juliano_fantozzi/EfbHjLnmPfBJlpu8b4ZpjRQB4mbOGpSaUmO5z0Xf3X8Utg?e=uAd9d8)

## Usecase: Ingress with mTLS and Federation 

To deploy the mesh using the Federation feature, run the script `usecases/federation/deploy-all.sh`.

Forward host port 7000 to port 7080 (ingressgateway-mtls pod port) inside the cluster:

```bash
> usecases/federation/forward-secure-port.sh

Forwarding from 127.0.0.1:7000 -> 7080
Forwarding from [::1]:7000 -> 7080
```

### Generate certs

Mint SVID in the trust domain `domain.test`:

```bash
> kubectl exec --stdin --tty -n spire2 spire-server-0  -- /opt/spire/bin/spire-server x509 mint -spiffeID spiffe://domain.test/myservice -socketPath /run/spire/sockets/server.sock
```

Copy the X509-SVID section of the output to a file `svid.pem`.
Copy the Private key section of the output to a file `key.pem`.

### Test TLS request

```bash
> curl --cert svid.pem --key key.pem -k -I https://localhost:8000/productpage

HTTP/2 200 
content-type: text/html; charset=utf-8
content-length: 5183
server: istio-envoy
```