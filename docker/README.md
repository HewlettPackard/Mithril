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
To clone the image you can use

```bash
make pull
```

After downloading the image you can execute

```bash
make run
```

# Pushing the image to Mirantis Secure Registry
Befor trying to push the image to MSR you need to set the environment variables in the `conf.env` file.


You need to update the `DOCKER_USER` and `DOCKER_PWD` fields, which are your docker user and your docker password. 

_Your **Docker password** is most likely your Private Access Token from MSR_

After setting the correct credentials in the `conf.env` file you can automatically build and publish the image with the command
```bash
make push
```

You can also just push the image if there is any update made to it
```bash
make publish
```