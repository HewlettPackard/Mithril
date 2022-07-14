# mithrilctl

Mithrilctl is a tool to easily deploy Mithril in a cluster.

## Requirements

1. kubectl
2. helm
3. A running cluster

## Setting up mithrilctl

At first, you need to build the mithrilctl binary. You can move it to the binary directory in order to be able to use it everywhere you need.

```bash
cd <Mithril repository path>/mithrilctl && go build -o mithril && sudo mv mithril /usr/local/bin/mithril
```

## Install Mithril

```bash
$ mithril install
```

## Getting installed manifests

```bash
$ mithril get manifest --spire
$ mithril get manifest --istio
```
