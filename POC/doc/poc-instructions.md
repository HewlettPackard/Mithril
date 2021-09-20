# Mithril POC

Currently, it deploys to local `kind ` cluster the istio `bookinfo` example. The four workloads from the example (details, productpage, ratings, and reviews) are deployed in the `default` namespace.

## Minimal configuration

- 4 CPUs
- 8 GB RAM
- 20 GB (for POC *only*)

## Requirements

- docker

### Install kubectl client

[Install the kubernetes client for your operating system](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Install istioctl:

```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.10.1 sh -
```

Should work with istio `1.9.1` and `1.10.1`.

## Install Kind 

Follow [kind install instructions](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)


## Install AWS CLI and configure it 

Follow [aws cli install and configure instructions](https://aws.amazon.com/cli/?nc1=h_ls)

## Create the cluster and the local docker registry

```bash
./create-kind-cluster.sh
```

## Running the POC locally
In order to run the POC locally,

```bash
TAG=stable \
HUB=public.ecr.aws/e4m8j0n8/mithril \
./deploy-all.sh
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
The SPIRE entries can be checked using the following command:

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
