#!/bin/bash

if [[ ${istio_branch} == release-1.10 ]]; then go install golang.org/dl/go1.16.12@latest &&
go1.16.12 download && go version; fi