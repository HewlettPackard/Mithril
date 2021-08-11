#!/bin/bash -xe

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


apt update -y
apt install docker.io awscli -y

echo "export AWS_ACCESS_KEY_ID=${access_key}" >> $HOME/.bashrc
echo "export AWS_SECRET_ACCESS_KEY=${secret_access_key}" >> $HOME/.bashrc
echo "export AWS_DEFAULT_REGION=${region}" >> $HOME/.bashrc

source $HOME/.bashrc

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind