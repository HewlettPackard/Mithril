FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

ENV TAG=my-build 
ENV HUB=localhost:5000 
ENV BUILD_WITH_CONTAINER=0
   
WORKDIR /mithril

RUN apt-get update \
    && apt-get -y install git make bash curl docker.io ruby ruby-dev rpm wget util-linux gcc libffi-dev libc6-dev apt-utils

RUN gem install --no-document fpm \
    && gem update fpm

# Go installation
RUN wget https://golang.org/dl/go1.16.1.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.16.1.linux-amd64.tar.gz \
    && rm -rf go1.16.1.linux-amd64.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

# Spire installation
RUN wget https://github.com/spiffe/spire/releases/download/v0.12.3/spire-0.12.3-linux-x86_64-glibc.tar.gz \
    && tar zvxf spire-0.12.3-linux-x86_64-glibc.tar.gz \
    && cp -r spire-0.12.3/. /opt/spire/ \
    && rm -rf spire-0.12.3-linux-x86_64-glibc.tar.gz

ENV PATH="${PATH}:/opt/spire/bin"

# Kubectl Installation
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm -rf kubectl

# Kind Installation
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin

# Istioctl Installation
RUN curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.10.1 sh - \
    && cp istio-1.10.1/bin/istioctl /usr/local/bin \
    && mv istio-1.10.1 istioctl-1.10.1

# Cloning istio source code
RUN git clone --single-branch --branch release-1.10 https://github.com/istio/istio.git ./istio-source

COPY . .

WORKDIR /mithril/istio-source

# Applying POC patch
RUN git apply /mithril/POC/patches/poc.1.10.patch

WORKDIR /mithril