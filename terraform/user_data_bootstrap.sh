#!/bin/bash

echo "TAG=${tag}" >> /etc/environment
echo "HUB=${hub}" >> /etc/environment
echo "AWS_DEFAULT_REGION=${region}" >> /etc/environment
echo "AWS_ACCESS_KEY_ID=${access_key}" >> /etc/environment
echo "AWS_SECRET_ACCESS_KEY=${secret_access_key}" >> /etc/environment
source /etc/environment


# redirects script stdout to log instance
# exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1