# Mithril POC

This POC is a WIP. 

Currently, it deploys to local `kind ` cluster the istio `bookinfo` example configured using static secrets that were 
generated from SVIDs issued by SPIRE. The four workloads from the example (details, productpage, ratings, and reviews) 
are deployed in the `default` namespace.

This POC requires at least 20GB of disk space and 2 CPUs, keep that in mind when setting up a VM. 

## Minimal configuration

- 4 CPUs
- 8 GB RAM
- 20 GB (for POC *only*)

## Requirements

- docker
- rpmbuild
- fpm
- make
- go 1.16
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
Note: You will need to clone the main istio repo to $GOPATH/src/istio.io/istio for the build commands to work correctly.
2. `git checkout release-1.10`
3. Apply patch `POC/patches/poc.1.10.patch`   
4. `export TAG=my-build`
5. `export HUB=localhost:5000`
6. `export BUILD_WITH_CONTAINER=0`
7. `make push`

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
namespace/spire created
clusterrolebinding.rbac.authorization.k8s.io/k8s-workload-registrar-role-binding created
clusterrole.rbac.authorization.k8s.io/k8s-workload-registrar-role created
configmap/k8s-workload-registrar created
Warning: apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
customresourcedefinition.apiextensions.k8s.io/spiffeids.spiffeid.spiffe.io created
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

```

Wait for all pods are to reach `Running` state:

```bash
kubectl get pods -A
```

Expected output: 

```
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
default              details-v1-c658fff7-cvj8d                    2/2     Running   0          6m19s
default              productpage-v1-5f85c6d9d8-mb6jm              2/2     Running   0          6m18s
default              ratings-v1-66db75fdb9-jv4ln                  2/2     Running   0          6m19s
default              reviews-v1-dbcbb4f7c-jzkh5                   2/2     Running   0          6m19s
default              reviews-v2-64854577cd-cw7zw                  2/2     Running   0          6m18s
default              reviews-v3-bd5fcc875-8b722                   2/2     Running   0          6m18s
istio-system         istio-ingressgateway-849d55784b-fwz7m        1/1     Running   0          6m36s
istio-system         istiod-5c79c669f9-7qx5m                      1/1     Running   0          6m49s
kube-system          coredns-74ff55c5b-pl5wd                      1/1     Running   0          19m
kube-system          coredns-74ff55c5b-zq798                      1/1     Running   0          19m
kube-system          etcd-kind-control-plane                      1/1     Running   0          19m
kube-system          kindnet-cxrzk                                1/1     Running   0          19m
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          19m
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          19m
kube-system          kube-proxy-xzjgd                             1/1     Running   0          19m
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          19m
local-path-storage   local-path-provisioner-78776bfc44-4dp4x      1/1     Running   0          19m
spire                spire-agent-w9jfd                            1/1     Running   0          6m21s
spire                spire-server-0                               2/2     Running   0          6m24s
```

### SPIRE Entries
When using [K8S Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar) for automatic workload registration within Kubernetes, you can check the created entries using the following command:

```
kubectl exec -i -t pod/spire-server-0 -n spire -c spire-server -- /bin/sh -c "bin/spire-server entry show -registrationUDSPath /run/spire/sockets/server.sock"
```

```
Found 9 entries
Entry ID         : f898b508-c044-42bb-88d0-d609233f7a3c
SPIFFE ID        : spiffe://example.org/bookinfo/details-v1
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 1
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:4b94243d-57dd-4174-85b2-909b6ff38240
DNS name         : details-v1-c658fff7-mcmmn
DNS name         : details.default.svc

Entry ID         : 848202ea-d779-4043-943e-dd64afe12502
SPIFFE ID        : spiffe://example.org/bookinfo/productpage
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 1
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:fdd4fabe-d27d-418a-bf3c-e97c7b364770
DNS name         : productpage-v1-5f85c6d9d8-djgsh
DNS name         : productpage.default.svc

Entry ID         : 5763d4e1-c71f-4fc3-9762-3fe86adbb44b
SPIFFE ID        : spiffe://example.org/bookinfo/ratings-v1
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 1
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:d91ec379-641f-4930-9f5f-5ba2fc425d0b
DNS name         : ratings-v1-66db75fdb9-l22xc
DNS name         : ratings.default.svc

Entry ID         : da35e53b-1e22-4201-b858-2197c4b7b45f
SPIFFE ID        : spiffe://example.org/bookinfo/reviews-v1
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 1
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:81d07b53-b3dc-4467-8fe0-9d7ace7df048
DNS name         : reviews-v1-dbcbb4f7c-t4wf4
DNS name         : reviews.default.svc

Entry ID         : 9949212b-1dd3-4fdb-bf8b-33fbfca31221
SPIFFE ID        : spiffe://example.org/bookinfo/reviews-v2
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 1
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:793d548a-2fb6-47e4-aa23-fafb37218408
DNS name         : reviews-v2-64854577cd-pwnsq
DNS name         : reviews.default.svc

Entry ID         : b4f0719b-2780-4665-8e67-75c18c082011
SPIFFE ID        : spiffe://example.org/bookinfo/reviews-v3
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 1
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:a2aa76c5-002a-46a3-aa59-ac8c2fe7ae7b
DNS name         : reviews-v3-bd5fcc875-g5dgw
DNS name         : reviews.default.svc

Entry ID         : a29ad9ac-d84e-427e-9113-9573cd67bec7
SPIFFE ID        : spiffe://example.org/istio-ingressgateway
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 1
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:istio-system
Selector         : k8s:pod-uid:a47b5a97-aaa9-474d-a8fb-81b76aed6236
DNS name         : istio-ingressgateway-7d5b8c789f-5ktzw
DNS name         : istio-ingressgateway.istio-system.svc

Entry ID         : 30335190-fafd-482b-8881-fd78b6685564
SPIFFE ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Parent ID        : spiffe://example.org/spire/server
Revision         : 0
TTL              : default
Selector         : k8s_psat:agent_node_uid:0a9ff095-dfd0-47ae-b7a5-a4e4c9fee819
Selector         : k8s_psat:cluster:demo-cluster

Entry ID         : 5064799a-ca9c-4c54-bfb1-2242cdfb4d44
SPIFFE ID        : spiffe://example.org/spire-agent
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/kind-control-plane
Revision         : 0
TTL              : default
Selector         : k8s:node-name:kind-control-plane
Selector         : k8s:ns:spire
Selector         : k8s:pod-uid:579332b8-a6c4-433e-bfc5-5d9647b75fc0
DNS name         : spire-agent-qbwkv
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

