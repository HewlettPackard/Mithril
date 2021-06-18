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
- kubectl
- istioctl
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- rpmbuild
- fpm
- make
- go 1.16

## Create the cluster and the local docker registry

```bash
./create-kind-cluster
```

## Build istio images

1. Clone https://github.com/istio/istio
  Note: You will need to clone the main istio repo to $GOPATH/src/istio.io/istio for the build commands to work correctly.
2. Switch to release-1.10 branch
3. export TAG=your-build
4. export HUB=localhost:5000
5. export BUILD_WITH_CONTAINER=0
6. make push

This will create the docker images with the tag "my-build" (used in 'istio-config.yaml'), and push them to the local docker registry.

(More info about building istio: https://github.com/istio/istio/wiki/Preparing-for-Development)

## Running the POC

```bash
./deploy-all
```

The output looks like: 

```
namespace/istio-system created
secret/istio configured
✔ Istio core installed
✔ Istiod installed
✔ Installation complete                                                                                                                                                        peerauthentication.security.istio.io/default created
secret/istio.details configured
secret/istio.productpage configured
secret/istio.ratings configured
secret/istio.reviews configured
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
```

Check that all pods are in state `Running`:

```bash
kubectl get pods -A
```

Expected output: 

```
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
default              details-v1-fcc5fd966-gk8c2                   2/2     Running   0          4m8s
default              productpage-v1-55cfb7d557-8rj79              2/2     Running   0          4m7s
default              ratings-v1-848b4fcb74-w4ftq                  2/2     Running   0          4m6s
default              reviews-v1-5978cfd6b-7b2z8                   2/2     Running   0          4m4s
default              reviews-v2-6c4549775c-vlpnl                  2/2     Running   0          4m5s
default              reviews-v3-7486f66464-rv9rx                  2/2     Running   0          4m5s
istio-system         istiod-dff875789-fxjt2                       1/1     Running   0          4m29s
kube-system          coredns-f9fd979d6-jd2hr                      1/1     Running   0          8m29s
kube-system          coredns-f9fd979d6-kd9r7                      1/1     Running   0          8m29s
kube-system          etcd-kind-control-plane                      1/1     Running   0          8m29s
kube-system          kindnet-npj22                                1/1     Running   1          8m30s
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          8m29s
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          8m29s
kube-system          kube-proxy-fg89x                             1/1     Running   0          8m30s
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          8m29s
local-path-storage   local-path-provisioner-78776bfc44-zbwh8      1/1     Running   0          8m29s
```


## Test example 

```bash
kubectl exec "$(kubectl get pod  -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings  -- curl -sS productpage:9080/productpage
```

The output is an HTML page that should not have any error sections. 


# Clean up

```bash
./cleanup
```

# TODOs:

- Add ingress gateway (requires some configuration on the `kind` cluster and new secrets configuration)
- Check whether the workloads can be deployed on separate namespaces (requires secrets update regenerating all the SVIDs 
  to accommodate so they have SPIFFE IDs that reflect the new namespaces)
- Add SPIRE to the deploy(?)  