#!/bin/bash

declare -a image_names=("install-cni" "operator" 
                        "istioctl" "app_sidecar_centos_7" 
                        "app_sidecar_centos_8" "app_sidecar_debian_10" "app_sidecar_debian_9"
                        "app_sidecar_ubuntu_focal" "app_sidecar_ubuntu_bionic" "app_sidecar_ubuntu_xenial"
                        "app" "proxyv2" "pilot"
                        )

for image_name in "${image_names[@]}"
do
  aws ecr set-repository-policy --repository-name mithril/$image_name --policy-text file://ecr-policy.json 
done
