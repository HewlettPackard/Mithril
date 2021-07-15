# Building the image

To build the image you can use the follow command
```bash
make build
```
The image has all the needed dependencies to be able to run and deploy the POC.

Further needed dependencies can be added if there is a need, to continue with Mithril development.

# Running the container
Before running the container you will need first to create a file to store the kube config created by kind.
```bash
mkdir -p $HOME/.kube && touch $HOME/.kube/config
```

Then you can run the container using the follow command
```bash
make run
```

This command will start the container and you can follow this [guide](https://github.hpe.com/sec-eng/istio-spire/blob/master/POC/README.md) in order to set up the environment.

# Cloning the image
The repo that the image will be stored still to be determined and the image that will be deployed to the repo it's waiting the team approval.

This documentation will be updated once the image it's deployed.