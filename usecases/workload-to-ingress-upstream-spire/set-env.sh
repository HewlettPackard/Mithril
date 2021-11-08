#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

timestamp() {
    date -u "+[%Y-%m-%dT%H:%M:%SZ]"
}

setup() {
    # Generates certs
    go run "../common/utils/gencerts.go" "$@"
}

log() {
    echo "${bold}$(timestamp) $*${norm}"
}

fingerprint() {
	# calculate the SHA1 digest of the DER bytes of the certificate using the
	# "coreutils" output format (`-r`) to provide uniform output from
	# `openssl sha1` on macOS and linux.
	openssl x509 -in "$1" -outform DER | openssl sha1 -r | awk '{print $1}'
}

mkdir nestedA && mkdir nestedB && mkdir -p data/server

wget https://github.com/spiffe/spire/releases/download/v"${LATEST_SPIRE_VERSION}"/spire-"${LATEST_SPIRE_VERSION}"-linux-x86_64-glibc.tar.gz

tar zvxf spire-"${LATEST_SPIRE_VERSION}"-linux-x86_64-glibc.tar.gz

mv spire-"${LATEST_SPIRE_VERSION}"/bin/spire-server . && rm -rf spire-"${LATEST_SPIRE_VERSION}"-linux-x86_64-glibc.tar.gz spire-"${LATEST_SPIRE_VERSION}"

# Starts root SPIRE deployment
log "Generating certificates for root SPIRE deployment and for nested nodes attestation"
setup "${DIR}" "${DIR}"

./spire-server run -config ./server.conf &

sleep 5

log "Bootstraping agents"
./spire-server bundle show -socketPath=/tmp/spire-server/private/api.sock > "${DIR}"/root-cert.pem

log "Creating regristration entry for nestedA spire-server"
./spire-server entry create \
       -parentID "spiffe://example.org/spire/agent/x509pop/$(fingerprint "${DIR}"/nestedA/agent-nestedA.crt.pem)" \
       -spiffeID "spiffe://example.org/ns/spire/sa/spire-server-nestedA" -dns spire-server-0 -dns spire-server.spire.svc \
       -selector "unix:uid:0" \
       -downstream \
       -ttl 3600 -socketPath="/tmp/spire-server/private/api.sock"

log "Creating regristration entry for nestedB spire-server"
./spire-server entry create \
       -parentID "spiffe://example.org/spire/agent/x509pop/$(fingerprint "${DIR}"/nestedB/agent-nestedB.crt.pem)" \
       -spiffeID "spiffe://example.org/ns/spire/sa/spire-server-nestedB" -dns spire-server-0 -dns spire-server.spire.svc \
       -selector "unix:uid:0" \
       -downstream \
       -ttl 3600 -socketPath="/tmp/spire-server/private/api.sock"
