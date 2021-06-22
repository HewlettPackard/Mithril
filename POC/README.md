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
$ curl -L https://istio.io/downloadIstio | sh -
```

Should work with istio `1.9.1` and `1.10.1`.

## Install Kind 

Follow [kind install instructions](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

## Create the cluster and the local docker registry

```bash
$ ./create-kind-cluster
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

```bash
$ ./deploy-all
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

Check that all pods are in state `Running`:

```bash
$ kubectl get pods -A
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

Create SPIRE registration entries for the node and the workload

```bash
$ ./spire/create-registration-entries.sh
```

```
Creating registration entry for the node...
Entry ID         : bf37cf2a-7a76-489a-8139-ba6def1b566d
SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
Parent ID        : spiffe://example.org/spire/server
Revision         : 0
TTL              : default
Selector         : k8s_sat:agent_ns:spire
Selector         : k8s_sat:agent_sa:spire-agent
Selector         : k8s_sat:cluster:demo-cluster

Creating registration entry for the workload...
Entry ID         : a2dfb64a-8cf7-4751-86e3-080944a37e31
SPIFFE ID        : spiffe://example.org/ns/default/sa/default
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:default
Selector         : k8s:sa:default
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



### Testing Spire Installation 
#### TODO: remove when spire-agent is successfully connecting to istio-proxy
```bash
$ kubectl apply -f spire/client-deployment.yaml
```

Starting a shell connection

```bash
$ kubectl exec -it $(kubectl get pods -o=jsonpath='{.items[0].metadata.name}' \
   -l app=client)  -- /bin/sh
```

Verify that the container can access the socket

```bash
$ /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/sockets/agent.sock
```

# Clean up

```bash
./cleanup
```

