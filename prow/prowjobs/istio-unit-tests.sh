#!/bin/sh

mkdir tmp && cd tmp

git clone --single-branch --branch release-1.10 https://github.com/istio/istio.git && cd istio
git apply /mithril/POC/patches/poc.release-1.10.patch

go get github.com/spiffe/go-spiffe/v2 && go mod tidy
make build
go test -race -coverprofile cover.out ./...