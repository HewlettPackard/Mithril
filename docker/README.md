# Building the image

To build the image you can use the following command. In this command you can specify any istio branch version and istioctl version you want to be added into the container. By default it is cloning the branch *_release-1.10_* and installing the istioctl _1.10.1_

```bash
make build ISTIO_VERSION=release-1.9 ISTIO_CTL_VERSION=1.9.1
```
The image has all the needed dependencies to be able to run and deploy the POC.

Further needed dependencies can be added if there is a need, to continue with Mithril development.

# Running the container

You can run the container using the following command
```bash
make run
```

This command will start the container and you can follow this [guide](https://github.hpe.com/sec-eng/istio-spire/blob/master/POC/README.md) in order to set up the environment.

# Pushing the image to Mirantis Secure Registry
Before trying to push the image to [MSR](https://hub.docker.hpecorp.net/repositories?namespace=sec-eng) you need to set the environment variables in the `conf.env` file.

You need to update the `DOCKER_USER` and `DOCKER_PWD` fields, which are your docker user and your docker password. 

_Your **Docker password** is most likely your Private Access Token from MSR_

After setting the correct credentials in the `conf.env` file you can automatically **build** and **publish** the image with the command

```bash
make push
```

You can also just publish the image if there is any update made to it
```bash
make publish
```

# Pulling the image
To download the image you can use

```bash
make pull
```

After downloading the image you can execute it with

```bash
make run
```
# Troubleshooting

If you encounter any problem during the building of istio images it's probably due to caching since the docker engine is shared from the host.

Exit the container and then you can execute these commands to clear the environment:

```bash
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -aq) --force
```

These commands will stop and remove all the containers, and clean up all the images.
