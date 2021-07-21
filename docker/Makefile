# Importing environment configuration
cnf ?= conf.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

.DEFAULT_GOAL := help

# Creating the command to be executed when building the image
CMD_BUILD := "docker build -t $(APP_NAME)"
ifdef ISTIO_VERSION
PATCH_VERSION = `echo $(ISTIO_VERSION) | cut -d'-' -f 2`
CMD_BUILD += " --build-arg ISTIO_VERSION=$(ISTIO_VERSION)"
endif
ifdef ISTIO_CTL_VERSION
CMD_BUILD += " --build-arg ISTIO_CTL_VERSION=$(ISTIO_CTL_VERSION)"
endif
ifdef PATCH_VERSION
CMD_BUILD += " --build-arg PATCH_VERSION=$(PATCH_VERSION)"
endif
CMD_BUILD += " -f ./Dockerfile .."

## Build the container.
build:
	eval $(CMD_BUILD)

## Run the container.
run:
	@mkdir -p $(HOME)/.kube && touch $(HOME)/.kube/config
	docker run -i -t --rm -v "$(DOCKER_SOCK_MAP)" -v "$(KUBE_CONFIG_MAP)" --network host --name $(APP_NAME) $(APP_NAME)

# Stop APP running containers
stop: 
	docker stop $(APP_NAME)

## Remove APP running containers.
rm: stop 
	docker rm $(APP_NAME)

## Clear the APP images.
clear-img: 
	docker rmi $(APP_NAME)

## Build and Start the container.
start: build run	   

## Build, tag and push the container.
push: build publish

## Pull the image and tag it as $APP_NAME:latest.
pull: tag-image

pull-image: 
	docker pull hub.docker.hpecorp.net/sec-eng/mithril

tag-image: pull-image
	docker tag hub.docker.hpecorp.net/sec-eng/mithril $(APP_NAME):latest
		   
## Login in and publish the image to the repo.
publish: login publish-latest publish-version

publish-latest: tag-latest
	docker push $(DOCKER_REPO)/$(APP_NAME):latest

publish-version: tag-version 
	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

tag-latest: 
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

tag-version: 
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

## Auto login to HPE docker hub MSR.
login: 
	docker login $(HUB_URL) -u $(DOCKER_USER) -p $(DOCKER_PWD)

#------------------------------------------------------------------------
# Document file
#------------------------------------------------------------------------

# VARIABLES
NAME = mithril
VERSION = 0.0.1
AUTHOR=HPE

# COLORS
GREEN := $(shell tput -Txterm setaf 2)
RESET := $(shell tput -Txterm sgr0)

TARGET_MAX_CHAR_NUM=20

## shows help.
help:
	@echo "--------------------------------------------------------------------------------"
	@echo "Author  : ${GREEN}$(AUTHOR)${RESET}"
	@echo "Project : ${GREEN}$(NAME)${RESET}"
	@echo "Version : ${GREEN}$(VERSION)${RESET}"
	@echo "--------------------------------------------------------------------------------"
	@echo ""
	@echo "Usage:"
	@echo "  ${GREEN}make${RESET} <target>"
	@echo "Targets:"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${GREEN}%-$(TARGET_MAX_CHAR_NUM)s${RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
{ lastLine = $$0 }' $(MAKEFILE_LIST)