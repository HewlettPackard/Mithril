#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt update -y
apt install docker.io awscli -y

aws configure set aws_access_key_id ${access_key}
aws configure set aws_secret_access_key ${secret_access_key}

echo "TAG=${tag}" >> /etc/environment 
source /etc/environment

# If you use tail -f the sed does not work, we can still see the secrets used to configure AWS
sed '/^+/d' /var/log/user-data.log > /var/log/user-data.log

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${hub}

docker pull ${hub}/mithril:${tag}

# Tagging for easier use within the docker command below
docker tag ${hub}/mithril:${tag} mithril-testing:${tag}

# Creating kubernetes config to use kubectl inside the container
mkdir -p $HOME/.kube && touch $HOME/.kube/config

# Creating kind cluster
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
/mithril/POC/create-kind-cluster.sh

docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c "cd /mithril/POC && TAG=${tag} HUB=${hub} ./deploy-all.sh"