#!/bin/bash -xe

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


apt update -y
apt install docker.io awscli -y

aws configure set aws_access_key_id ${access_key}
aws configure set aws_secret_access_key ${secret_access_key}
echo "TAG=${tag}" >> /etc/environment 
source /etc/environment

sed '/^+/d' /var/log/user-data.log > /var/log/user-data.log

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 529024819027.dkr.ecr.us-east-1.amazonaws.com

docker pull 529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril:${tag}