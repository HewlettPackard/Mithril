#!/bin/sh

mkdir tmp && cd tmp

git clone --single-branch --branch $BRANCH https://github.com/istio/istio.git && cd istio
git apply /home/prow/go/src/github.com/HewlettPackard/Mithril/POC/patches/poc.$BRANCH.patch

go get github.com/spiffe/go-spiffe/v2 && go mod tidy
make build

go install github.com/jstemmer/go-junit-report@latest

go test -v 2>&1 | $GOPATH/bin/go-junit-report > junit.xml