FROM 529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril:ubuntu-20.04@sha256:1e48201ccc2ab83afc435394b3bf70af0fa0055215c1e26a5da9b50a1ae367c9

ARG DEBIAN_FRONTEND=noninteractive
ARG ISTIO_VERSION=release-1.10
ARG ISTIO_CTL_VERSION=1.10.1
ARG PATCH_VERSION=1.10
ARG GO_VERSION=1.17.4
ARG SPIRE_VERSION=1.1.1

ENV TAG=my-build 
ENV HUB=localhost:5000 
ENV BUILD_WITH_CONTAINER=0
   
WORKDIR /mithril

RUN apt-get update \
    && apt-get -y install git make bash curl docker.io ruby ruby-dev rpm wget util-linux gcc libffi-dev libc6-dev apt-utils

RUN gem install --no-document fpm \
    && gem update fpm

# AWS CLI installation
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip -o awscliv2.zip \
    && rm -rf awscliv2.zip \
    && ./aws/install --update

# Go installation
RUN wget https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz \
    && rm -rf go$GO_VERSION.linux-amd64.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

# Spire installation
RUN wget https://github.com/spiffe/spire/releases/download/v$SPIRE_VERSION/spire-$SPIRE_VERSION-linux-x86_64-glibc.tar.gz \
    && tar zvxf spire-$SPIRE_VERSION-linux-x86_64-glibc.tar.gz \
    && cp -r spire-$SPIRE_VERSION/. /opt/spire/ \
    && rm -rf spire-$SPIRE_VERSION-linux-x86_64-glibc.tar.gz

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
RUN curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_CTL_VERSION sh - \
    && cp istio-$ISTIO_CTL_VERSION/bin/istioctl /usr/local/bin \
    && mv istio-$ISTIO_CTL_VERSION istioctl-$ISTIO_CTL_VERSION

# Terraform
RUN apt-get install -y gnupg software-properties-common curl \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update && apt-get install terraform

WORKDIR /mithril