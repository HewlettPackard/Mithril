# Mithril POC

This POC is a WIP. 

Currently, it deploys to local `kind ` cluster the istio `bookinfo` example configured using static secrets that were 
generated from SVIDs issued by SPIRE. The four workloads from the example (details, productpage, ratings, and reviews) 
are deployed in the `default` namespace.

## Requirements

### Install kubectl client

[Install the kubernetes client for your operating system](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Install istioctl:

```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.10.1 sh -
```

Should work with istio `1.9.1` and `1.10.1`.

## Install Kind 

Follow [kind install instructions](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

## Create the cluster and the local docker registry

```bash
./create-kind-cluster
```

## Build istio images

1. Clone https://github.com/istio/istio
2. `git checkout release-1.10`   
2. export TAG=your-build
3. export HUB=localhost:5000
4. export BUILD_WITH_CONTAINER=0
5. make push

This will create the docker images with the tag `my-build` (used in 'istio-config.yaml'), and push them to the local docker registry.

(More info about building istio: https://github.com/istio/istio/wiki/Preparing-for-Development)

## Running the POC

Before running the deploy script, specify your trust domain and cluster name on the spire server config at `spire/server-configmap.yaml`

```bash
./deploy-all
```

The output should look like: 

```
namespace/istio-system created
secret/istio created
secret/istio.istio-ingressgateway-service-account created
configmap/istio-ca-root-cert created
✔ Istio core installed                                                                                                                                                                                                        
✔ Istiod installed                                                                                                                                                                                                            
✔ Ingress gateways installed                                                                                                                                                                                                  
✔ Installation complete                                                                                                                                                                                                       Thank you for installing Istio 1.10.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/KjkrDnMPByq7akrYA
peerauthentication.security.istio.io/default created
secret/istio.details created
secret/istio.productpage created
secret/istio.ratings created
secret/istio.reviews created
configmap/istio-ca-root-cert created
service/details created
serviceaccount/details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/productpage created
deployment.apps/productpage-v1 created
gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo-service created
destinationrule.networking.istio.io/enable-mtls created
namespace/spire created
serviceaccount/spire-server created
configmap/spire-bundle created
clusterrole.rbac.authorization.k8s.io/spire-server-trust-role created
clusterrolebinding.rbac.authorization.k8s.io/spire-server-trust-role-binding created
configmap/spire-server created
statefulset.apps/spire-server created
service/spire-server created
serviceaccount/spire-agent created
clusterrole.rbac.authorization.k8s.io/spire-agent-cluster-role created
clusterrolebinding.rbac.authorization.k8s.io/spire-agent-cluster-role-binding created
configmap/spire-agent created
daemonset.apps/spire-agent created

```

Wait for all pods are to reach `Running` state:

```bash
kubectl get pods -A
```

Expected output: 

```
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
default              details-v1-87b44dc44-ztq9k                   2/2     Running   0          2m37s
default              productpage-v1-675dbf6dc7-rtccq              2/2     Running   0          2m35s
default              ratings-v1-65ffcb969b-958cg                  2/2     Running   0          2m36s
default              reviews-v1-67458875c9-tvt66                  2/2     Running   0          2m36s
default              reviews-v2-fcbd767db-29tpf                   2/2     Running   0          2m36s
default              reviews-v3-6c84468bbf-jq4th                  2/2     Running   0          2m35s
istio-system         istio-ingressgateway-7df65c94db-bk7r8        1/1     Running   0          2m42s
istio-system         istiod-8596965f55-6fr2t                      1/1     Running   0          2m46s
kube-system          coredns-558bd4d5db-cf5rv                     1/1     Running   0          4m15s
kube-system          coredns-558bd4d5db-pbxqv                     1/1     Running   0          4m15s
kube-system          etcd-kind-control-plane                      1/1     Running   0          4m16s
kube-system          kindnet-l49vn                                1/1     Running   0          4m16s
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          4m16s
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          4m16s
kube-system          kube-proxy-ffb2c                             1/1     Running   0          4m16s
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          4m29s
local-path-storage   local-path-provisioner-547f784dff-slwfd      1/1     Running   0          4m15s
spire                spire-agent-nnkpb                            1/1     Running   0          2m29s
spire                spire-server-0                               1/1     Running   0          2m32s
```

Then, create SPIRE registration entries

```bash
CLUSTER_NAME=your-cluster TRUST_DOMAIN=your-domain \
./spire/create-registration-entries.sh
```

```
Creating registration entry for the node...
Entry ID         : ed8db9a1-ba4b-4d62-8c75-9fcc4b14f004
SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
Parent ID        : spiffe://example.org/spire/server
Revision         : 0
TTL              : default
Selector         : k8s_sat:agent_ns:spire
Selector         : k8s_sat:agent_sa:spire-agent
Selector         : k8s_sat:cluster:demo-cluster

Creating registration entry for ingress...
Entry ID         : 75afec49-118a-49e8-859b-5b6a0191440e
SPIFFE ID        : spiffe://example.org/istio/ingressgateway
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:istio-system
Selector         : k8s:pod-label:app=istio-ingressgateway

Creating registration entry for the bookinfo services...
Entry ID         : 5b3a2d3e-8838-48cc-aac8-7073aeece819
SPIFFE ID        : spiffe://example.org/bookinfo/details
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:default
Selector         : k8s:sa:details

Entry ID         : 0b852e64-e7d3-4c8e-889c-94962bca02ef
SPIFFE ID        : spiffe://example.org/bookinfo/productpage
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:default
Selector         : k8s:sa:productpage

Entry ID         : 486343c1-c7b6-4baf-8552-d4651868d3d3
SPIFFE ID        : spiffe://example.org/bookinfo/ratings
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:default
Selector         : k8s:sa:ratings

Entry ID         : 0321df08-c2be-4300-a26d-9c37c30a53a7
SPIFFE ID        : spiffe://example.org/bookinfo/reviews
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:default
Selector         : k8s:sa:reviews
```


## Test example 

### Inside the cluster:

```bash
kubectl exec "$(kubectl get pod  -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings  -- curl -sS productpage:9080/productpage
```

The output is an HTML page that should not have any error sections. 

### Outside the cluster:

Forward host port 8000 to port 8080 (ingressgateway pod port) inside the cluster:

```bash
./forward-port

Forwarding from 127.0.0.1:8000 -> 8080
Forwarding from [::1]:8000 -> 8080
```

Make a request from the host:

```bash
curl localhost:8000/productpage
```

Or open in the browser `localhost:8000/productpage`.

The output is an HTML page that should not have any error sections.

# Clean up

```bash
./cleanup
```

