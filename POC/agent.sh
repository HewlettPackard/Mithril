#!/bin/bash

# Creates folders for secret management
mkdir -p ./var/run/secrets/tokens ./var/run/secrets/istio

# Creates temporary script to set some k8's configurations
mkdir -p ./.temp
echo '#!/bin/bash' > ./.temp/temp.sh
echo -n "echo " >> ./.temp/temp.sh && echo -n "'" >> ./.temp/temp.sh && echo -n '{"kind":"TokenRequest","apiVersion":"authentication.k8s.io/v1","spec":{"audiences":["istio-ca"], "expirationSeconds":2592000}}' >> ./.temp/temp.sh && echo -n "'" >> ./.temp/temp.sh
echo ' | \' >> ./.temp/temp.sh
echo 'kubectl create --raw /api/v1/namespaces/${1:-default}/serviceaccounts/${2:-default}/token -f - | jq -j ".status.token" > ./var/run/secrets/tokens/istio-token' >> ./.temp/temp.sh
bash ./.temp/temp.sh
rm -rf ./.temp

# Get root-cert from secret of the POC and writes to file in the default Istio path for the root-cert
kubectl -n istio-system get configmaps istio-ca-root-cert  -ojsonpath='{.data.root-cert\.pem}' | base64 > ./var/run/secrets/istio/root-cert.pem

# Get certs from secrets of the POC and writes to files in the default Istio path
kubectl -n istio-system get secrets istiod-certs -ojsonpath='{.data.root-cert\.pem}' | base64 -d > ./etc/certs/root-cert.pem
kubectl -n istio-system get secrets istiod-certs -ojsonpath='{.data.istiod-key\.pem}' | base64 -d > ./etc/certs/key.pem
kubectl -n istio-system get secrets istiod-certs -ojsonpath='{.data.istiod-svid\.pem}' | base64 -d > ./etc/certs/cert-chain.pem


# Get script input parameters
# Flags:
# -r (remote) -> '1' for container build, else for local build 
# -t (TAG) -> <your-build-tag>
# -h (HUB) -> <your-hub-registry>
# -c (PILOT_CERT_PROVIDER) -> sets the 'PILOT_CERT_PROVIDER' Istio environment variable, default value is 'istio'
# use 'SPIRE' to run with our implementation of the cert provider 
while getopts r:t:h:c: flag
do
    case "${flag}" in
        r*) r=${OPTARG};;
        t*) TAG=${OPTARG};;
        h*) HUB=${OPTARG};;
        c*) PILOT_CERT_PROVIDER=${OPTARG};;
    esac
done

# Runs istio agent in local mode by default
# If flag 'r' (remote) is set to '1', runs the istio agent in container mode
if [[ $r = "1" ]]
then
    echo "Running istio agent container!"
    if [[ $HUB = "" ]]
    then
        echo "Empty HUB env var!"
        exit
    fi
    if [[ $TAG = "" ]]
    then
        echo "Empty TAG env var!"
        exit
    fi
    echo "TAG: $TAG";
    echo "HUB: $HUB";

    if [[ $PILOT_CERT_PROVIDER != "" ]]
    then
        echo "PILOT_CERT_PROVIDER="$PILOT_CERT_PROVIDER
    fi
    
    echo "discoveryAddress: localhost:15012
statusPort: 15020
terminationDrainDuration: 0s
tracing: {}" > $PWD/proxy-config-docker.yaml

    TAG=$TAG HUB=$HUB BUILD_WITH_CONTAINER=0 DOCKER_TARGETS=docker.proxyv2 make push

    if [[ $PILOT_CERT_PROVIDER == "SPIRE" ]]
    then
        echo "PILOT_CERT_PROVIDER="$PILOT_CERT_PROVIDER
        docker run -it -v $PWD/var/run/secrets/tokens/istio-token:/var/run/secrets/tokens/istio-token -v /tmp/agent.sock:/tmp/agent.sock \
            -v $PWD/var/run/secrets/istio/:/var/run/secrets/istio/ \
            -v $PWD/etc/certs/:/etc/certs/ \
            --network host \
            -e SPIFFE_ENDPOINT_SOCKET="unix:///tmp/agent.sock" \
            -e TRUST_DOMAIN="example.org" \
            -e PILOT_ENABLE_XDS_IDENTITY_CHECK=true \
            -e ENABLE_CA_SERVER=false \
            -e PILOT_CERT_PROVIDER=$PILOT_CERT_PROVIDER \
            -e PROXY_CONFIG="$(< $PWD/proxy-config-docker.yaml envsubst)" \
            $HUB/proxyv2:$TAG proxy sidecar
    else
        docker run -it -v $PWD/var/run/secrets/tokens/istio-token:/var/run/secrets/tokens/istio-token -v /tmp/agent.sock:/tmp/agent.sock \
            -v $PWD/var/run/secrets/istio/:/var/run/secrets/istio/ \
            -v $PWD/etc/certs/:/etc/certs/ \
            --network host \
            -e PILOT_ENABLE_XDS_IDENTITY_CHECK=true \
            -e ENABLE_CA_SERVER=false \
            -e PILOT_CERT_PROVIDER=$PILOT_CERT_PROVIDER \
            -e PROXY_CONFIG="$(< $PWD/proxy-config-docker.yaml envsubst)" \
            $HUB/proxyv2:$TAG proxy sidecar
    fi
else
    echo "Running istio agent locally!"
    if [[ $PILOT_CERT_PROVIDER != "" ]]
    then
        echo "PILOT_CERT_PROVIDER="$PILOT_CERT_PROVIDER
    fi
    echo "binaryPath: $PWD/out/linux_amd64/envoy
configPath: $PWD
proxyBootstrapTemplatePath: $PWD/tools/packaging/common/envoy_bootstrap.json
discoveryAddress: localhost:15012
statusPort: 15020
terminationDrainDuration: 0s
tracing: {}" > $PWD/proxy-config.yaml
    if [[ $PILOT_CERT_PROVIDER == "SPIRE" ]]
    then
        SPIFFE_ENDPOINT_SOCKET="unix:///tmp/agent.sock" TRUST_DOMAIN="example.org" PILOT_ENABLE_XDS_IDENTITY_CHECK=true PILOT_CERT_PROVIDER=$PILOT_CERT_PROVIDER PROXY_CONFIG="$(< $PWD/proxy-config.yaml envsubst)" go run ./pilot/cmd/pilot-agent proxy sidecar
    else
        PILOT_ENABLE_XDS_IDENTITY_CHECK=true PROXY_CONFIG="$(< $PWD/proxy-config.yaml envsubst)" go run ./pilot/cmd/pilot-agent proxy sidecar
    fi
fi
