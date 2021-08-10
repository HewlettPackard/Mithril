#!/bin/bash
# Environment Variables
export TAG=stable
export HUB=529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril

# Colors
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get POC from AWS S3
echo -e "${PURPLE}Downloading POC version from AWS S3...${NC}"

aws s3 cp s3://mithril-customer-assets/mithril.tar.gz .
mkdir -p $HOME/mithril && tar -xf ./mithril.tar.gz -C $HOME/mithril 

echo -e "${PURPLE}Creating Docker Secrets for AWS...${NC}"
$HOME/mithril/create-docker-registry-secret.sh

echo -e "${PURPLE}Creating namespaces...${NC}"
$HOME/mithril/create-namespaces.sh

echo -e "${PURPLE}Deploying Spire...${NC}"

# Call script to deploy Spire
cd $HOME/mithril/spire/
./deploy-spire.sh

echo -e "${GREEN}$(kubectl wait pod --for=condition=Ready -l app=spire-agent -n spire)${NC}"

# Call script to deploy Istio
echo -e "${PURPLE}Deploying Istio...${NC}"
cd $HOME/mithril/istio
./deploy-istio.sh

# Check running pods
echo -e "${GREEN}$(kubectl get pods -n istio-system)${NC}"

sleep 10.0

# Deploying Bookinfo Application
echo -e "${PURPLE}Deploying Bookinfo application...${NC}"

cd $HOME/mithril/bookinfo
./deploy-bookinfo.sh

# Port Forwading Services
$HOME/mithril/forward-port.sh

# Waiting for pods to be ready 
kubectl wait pod --for=condition=Ready -l app=productpage
kubectl wait pod --for=condition=Ready -l app=details
kubectl wait pod --for=condition=Ready -l app=reviews
kubectl wait pod --for=condition=Ready -l app=ratings

# Check running pods
echo -e "${GREEN}$(kubectl get pods -n default)${NC}"

sleep 10.0

# Check Product page SA response
echo -e "${GREEN}$(curl localhost:8000/productpage)${NC}"

sleep 10.0

# Demonstrating SPIRE in operation
cd $HOME/mithril/spire

# Workload Log
kubectl logs $(kubectl get pod -l app=details -o jsonpath='{.items[0].metadata.name}') -c istio-proxy >> workload.log

# SPIRE agent log
kubectl logs $(kubectl get pod -l app=spire-agent -o jsonpath='{.items[0].metadata.name}' -n spire) -n spire >> spire-agent.log

echo -e "${PURPLE}Log for SPIRE in operation availabe at $PWD${NC}"