#!/bin/bash

# Environment Variables
export TAG=stable
export HUB=public.ecr.aws/e4m8j0n8/mithril
export BASE_DIR=$HOME/mithril

# Colors
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get POC from AWS S3
echo -e "${PURPLE}Downloading POC version from AWS S3...${NC}"

# aws s3 cp s3://mithril-customer-assets/mithril.tar.gz . --profile scytale
mkdir -p $BASE_DIR && tar -xf ./mithril.tar.gz -C $BASE_DIR 

# echo -e "${PURPLE}Creating Docker Secrets for AWS...${NC}"
$BASE_DIR/POC/create-docker-registry-secret.sh

echo -e "${PURPLE}Creating namespaces...${NC}"
$BASE_DIR/usecases/federation/create-namespaces.sh

echo -e "${PURPLE}Deploying Spire...${NC}"

# Call script to deploy Spire 1
cd $BASE_DIR/usecases/federation/spire
./deploy-spire.sh $BASE_DIR

# Wait SPIRE Agente to be ready
echo -e "${GREEN}$(kubectl wait pod --for=condition=Ready -l app=spire-agent -n spire)${NC}"

# Call script to deploy Spire 2
cd $BASE_DIR/usecases/federation/spire2
./deploy-spire.sh

# Wait SPIRE Server 1 to be ready
echo -e "${GREEN}$(kubectl wait --for=condition=ready pod spire-server-0 -n spire2 --timeout=-1s)${NC}"

# Echo bundle from SPIRE server
bundle=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire2  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

# Wait SPIRE Server 2 to be ready
echo -e "${GREEN}$(kubectl wait --for=condition=ready pod spire-server-0 -n spire --timeout=-1s)${NC}"

# Set domain.test bundle to SPIRE
kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://domain.test -socketPath /run/spire/sockets/server.sock <<< "$bundle"

# Mint x509 SVID
kubectl exec --stdin --tty -n spire2 spire-server-0  -- /opt/spire/bin/spire-server x509 mint -spiffeID spiffe://domain.test/myservice -socketPath /run/spire/sockets/server.sock >> mint-cert.pem

# Call script to deploy Istio
echo -e "${PURPLE}Deploying Istio...${NC}"
cd $BASE_DIR/usecases/federation/istio
./deploy-istio.sh $BASE_DIR

# Check running pods
echo -e "${GREEN}$(kubectl get pods -n istio-system)${NC}"

sleep 10.0

# Deploying Bookinfo Application
echo -e "${PURPLE}Deploying Bookinfo application...${NC}"

cd $BASE_DIR/POC/bookinfo
./deploy-bookinfo.sh

# Port Forwading Services
echo -e "${PURPLE}Port Forwarding Services...${NC}"
$BASE_DIR/POC/forward-port.sh
$BASE_DIR/usecases/federation/forward-secure-port.sh

# Waiting for pods to be ready 
echo -e "${GREEN}$(kubectl wait pod --for=condition=Ready -l app=productpage --timeout=-1s)${NC}"
echo -e "${GREEN}$(kubectl wait pod --for=condition=Ready -l app=details --timeout=-1s)${NC}"
echo -e "${GREEN}$(kubectl wait pod --for=condition=Ready -l app=reviews --timeout=-1s)${NC}"
echo -e "${GREEN}$(kubectl wait pod --for=condition=Ready -l app=ratings --timeout=-1s)${NC}"

# Check running pods
echo -e "${PURPLE}$(kubectl get pods -n default)${NC}"

sleep 10.0

# Check Product page SA response
echo -e "${GREEN}$(curl localhost:8000/productpage)${NC}"

sleep 10.0

# Demonstrating SPIRE in operation
cd $BASE_DIR/POC/spire

# Workload Log
kubectl logs $(kubectl get pod -l app=details -o jsonpath='{.items[0].metadata.name}') -c istio-proxy >> workload.log

# SPIRE agent log
kubectl logs $(kubectl get pod -l app=spire-agent -o jsonpath='{.items[0].metadata.name}' -n spire) -n spire >> spire-agent.log

echo -e "${PURPLE}Log for SPIRE in operation availabe at $PWD${NC}"

# Demonstrating Federation
cd $BASE_DIR/usecases/federation/spire2

# Extracting key and svid from mintend x509
openssl pkey -in mint-cert.pem -out key.pem
openssl x509 -in mint-cert.pem -out svid.pem

# Test TLS request with the svid.pem and key.pem generated
echo -e "${GREEN}$(curl --cert svid.pem --key key.pem -k -I https://localhost:7000/productpage)${NC}"