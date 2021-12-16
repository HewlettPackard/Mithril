#!/bin/bash

if [[ ${istio_branch} == release-1.10 ]]; then rm -rf /usr/local/go &&
wget https://golang.org/dl/go1.16.12.linux-amd64.tar.gz &&
tar -C /usr/local -xzf go1.16.12.linux-amd64.tar.gz &&
rm -rf go1.16.12.linux-amd64.tar.gz; fi