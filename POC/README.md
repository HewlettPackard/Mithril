# Mithril POC

[![Build status badge](https://jenkins.docker.hpecorp.net/buildStatus/icon?job=sec-eng%2Fistio-spire%2Fmaster)](https://jenkins.docker.hpecorp.net/job/sec-eng/job/istio-spire/job/master/)

This POC is a WIP. 

Currently, it deploys to local `kind` cluster the istio `bookinfo` example configured using static secrets that were 
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

### Install istioctl

```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.10.1 sh -
```

Should work with istio `1.9.1` and `1.10.1`.

## Install Kind 

Follow [kind install instructions](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

## Create the cluster and the local docker registry

```bash
./create-kind-cluster.sh
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

This will create the docker images with the tag `my-build`, and push them to the local docker registry (`localhost:5000`).

(More info about building istio: https://github.com/istio/istio/wiki/Preparing-for-Development)

## Running the POC locally

Before running the deploy script, specify your trust domain and cluster name on the spire server config at `spire/server-configmap.yaml`

```bash
TAG=my-build \
HUB=localhost:5000 \
./deploy-all.sh
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
kubectl exec -i -t pod/spire-server-0 -n spire -c spire-server -- /bin/sh -c "bin/spire-server entry show -socketPath /run/spire/sockets/server.sock"
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
./forward-port.sh

Forwarding from 127.0.0.1:8000 -> 8080
Forwarding from [::1]:8000 -> 8080
```

Make a request from the host:

```bash
curl localhost:8000/productpage
```

Or open in the browser `localhost:8000/productpage`.

The output is an HTML page that should not have any error sections.

## Deploying the POC to Amazon EKS

1. Install [kubectl](#install-kubectl-client) and [istioctl](#install-istioctl).

2. Install [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html) and [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

3. Set up the credentials for AWS.
```bash
aws configure
```

4. Create an EKS cluster. Name the cluster at will, choose a region, and configure an AWS Key Pair or an SSH key (optional). This may take a while.
```bash
eksctl create cluster \
    --name <your-cluster-name> \
    --region us-east-1 \
    --with-oidc \
    --ssh-access \
    --ssh-public-key my-key-pair \
    --managed
```

5. Deploy the latest (master) tag using the images from the ECR repository.
```bash
TAG=latest \
HUB=public.ecr.aws/e4m8j0n8/mithril \
./deploy-all.sh
```
When you are done, you can [clean up your istio deployment](#clean-up), and then delete the EKS cluster.
```bash
eksctl delete cluster --region us-east-1 --name poc-cluster
```

# Clean up

```bash
./cleanup-all.sh
```

## Running Istio Agent

Follow [Running Istio Agent Wiki](https://github.hpe.com/sec-eng/istio-spire/wiki/Running-Istio-Agent-locally-or-in-container)