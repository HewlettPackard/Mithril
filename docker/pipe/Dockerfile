FROM ubuntu:latest@sha256:b6b83d3c331794420340093eb706a6f152d9c1fa51b262d9bf34594887c2c7ac

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get -y install git make bash curl util-linux gcc libffi-dev libc6-dev apt-utils wget \
    apt-transport-https ca-certificates gnupg lsb-release

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update
RUN apt-get -y install docker.io
RUN apt-get -y install ruby ruby-dev rubygems build-essential rpm
RUN gem install --no-document fpm

# AWS CLI installation
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip -o awscliv2.zip
RUN ./aws/install --update

# Go installation
RUN wget https://golang.org/dl/go1.17.5.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.17.5.linux-amd64.tar.gz

ENV PATH=/usr/local/go/bin:$PATH

# Terraform
RUN apt-get install -y gnupg software-properties-common curl \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update && apt-get install terraform

# Docker buildx installation
RUN wget https://github.com/docker/buildx/releases/download/v0.7.1/buildx-v0.7.1.linux-amd64 \
    && mv buildx-v0.7.1.linux-amd64 docker-buildx && chmod +x docker-buildx \
    && mkdir -p $HOME/.docker/cli-plugins && mv docker-buildx $HOME/.docker/cli-plugins

ENV PATH=$PATH:$HOME/.docker/cli-plugins
