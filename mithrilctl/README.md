# mithrilctl

Mithrilctl is a tool to easily deploy Mithril in a cluster.

## Requirements

1. kubectl
2. helm
3. A running cluster

## Setting up mithrilctl

At first, you need to build the mithrilctl binary. You can move it to the binary directory in order to be able to use it everywhere you need.

```bash
cd <Mithril repository path>/mithrilctl && go build -o mithrilctl && sudo mv mithrilctl /usr/local/bin/mithrilctl
```

```shell
$ mithrilctl
Path for Mithril repository is not set!

Enter the path for your Mithril repository: <Mithril repository full path>
```

## Install Mithril

```bash
$ mithrilctl install
```

## Getting installed manifests

```bash
$ mithrilctl get manifest --spire
$ mithrilctl get manifest --istio
```
