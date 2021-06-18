# Mithril POC

This POC is a WIP. 

Currently, it deploys to local `kind ` cluster the istio `bookinfo` example configured using static secrets that were 
generated from SVIDs issued by SPIRE. The four workloads from the example (details, productpage, ratings, and reviews) 
are deployed in the `default` namespace.

This POC requires at least 20GB of disk space and 2 CPUs, keep that in mind when setting up a VM. 

## Minimal configuration

- 2 CPUs
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
curl -L https://istio.io/downloadIstio | sh -
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

```bash
./deploy-all
```

The output looks like: 

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
service/details created
serviceaccount/details created
deployment.apps/details-v1 created
service/productpage created
serviceaccount/productpage created
deployment.apps/productpage-v1 created
service/ratings created
serviceaccount/ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo-service created
destinationrule.networking.istio.io/enable-mtls created
```

Check that all pods are in state `Running`:

```bash
kubectl get pods -A
```

Expected output: 

```
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
default              details-v1-6c79dd8447-d6qwt                  2/2     Running   0          5m36s
default              productpage-v1-5d767c49cd-rd7f8              2/2     Running   0          5m35s
default              ratings-v1-7fd67f6bc9-ql2qf                  2/2     Running   0          5m35s
default              reviews-v1-65fd695cf6-9gxkm                  2/2     Running   0          5m34s
default              reviews-v2-59958f8d4f-tf2hr                  2/2     Running   0          5m34s
default              reviews-v3-549bff66b-d6nz4                   2/2     Running   0          5m34s
istio-system         istio-ingressgateway-798dc44d6f-9xmz4        1/1     Running   0          6m12s
istio-system         istiod-688ff97bb4-z7gkz                      1/1     Running   0          6m20s
kube-system          coredns-f9fd979d6-8cdpx                      1/1     Running   0          7m6s
kube-system          coredns-f9fd979d6-tgp9d                      1/1     Running   0          7m6s
kube-system          etcd-kind-control-plane                      1/1     Running   0          7m7s
kube-system          kindnet-xh9rw                                1/1     Running   1          7m7s
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          7m7s
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          7m7s
kube-system          kube-proxy-c7qrn                             1/1     Running   0          7m7s
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          7m7s
local-path-storage   local-path-provisioner-78776bfc44-kk9nn      1/1     Running   0          7m6s
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

