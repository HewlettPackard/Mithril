FROM ubuntu:latest

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

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN wget https://golang.org/dl/go1.16.1.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.16.1.linux-amd64.tar.gz

ENV PATH=/usr/local/go/bin:$PATH