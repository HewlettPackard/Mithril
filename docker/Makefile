# Importing environment configuration
cnf ?= conf.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# DOCKER TASKS

# Build the container
build:
	docker build -t $(APP_NAME) -f ./Dockerfile ..

# Runs the container
run:
	docker run -i -t --rm -v "$(DOCKER_SOCK_MAP)" -v "$(KUBE_CONFIG_MAP)" --network host --name $(APP_NAME) $(APP_NAME)

# Stop running containers
stop: 
	docker stop $(APP_NAME)

# Stop and remove running containers
rm: stop 
	docker rm $(APP_NAME)

# Clear the APP images and containers
clear: rm 
	   docker rmi $(APP_NAME)

# Clear the APP images
clear-img:
	   docker rmi $(APP_NAME)

# Build and Start the container
start: build run	   

# Docker release - build, tag and push the container
push: build publish

# Docker publish
publish: login publish-latest

publish-latest: tag-latest
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):latest

# publish-version: tag-version 
# 	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
# 	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

tag-latest: 
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

# tag-version: 
# 	@echo 'create tag $(VERSION)'
# 	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

login: ## Auto login to HPE docker hub MSR
	docker login $(HUB_URL) -u $(DOCKER_USER) -p $(DOCKER_PWD)