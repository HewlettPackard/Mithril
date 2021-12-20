#!/bin/bash

# Check istio release version, release-1.10 has a go1.16 dependency

if [[ ${istio_branch} == release-1.10 ]]; then go install golang.org/dl/go1.16.12@latest &&
./go/bin/go1.16.12 download && export PATH="$PWD/sdk/go1.16.12/bin:$PATH" && go version; fi
