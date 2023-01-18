#!/usr/bin/env zsh
set -eo pipefail

export KUBECONFIG=

kubectl get deployments -A -o json > /tmp/deployments.json
kubectl get statefulsets -A -o json > /tmp/statefulsets.json
kubectl get daemonset -A -o json > /tmp/daemonset.json

cat /dev/null > /tmp/deploy-images.txt
cat /tmp/deployments.json | jq '.items[] | .spec | .template | .spec | .containers[] | .image' | sed 's/\"//g' >> /tmp/deploy-images.txt
cat /tmp/deployments.json | jq '.items[] | .spec | .template | .spec | select(.initContainers) | .initContainers[] | .image' | sed 's/\"//g' >> /tmp/deploy-images.txt

cat /dev/null > /tmp/sts-images.txt
cat /tmp/statefulsets.json | jq '.items[] | .spec | .template | .spec | .containers[] | .image' | sed 's/\"//g' >> /tmp/sts-images.txt
cat /tmp/statefulsets.json | jq '.items[] | .spec | .template | .spec | select(.initContainers) | .initContainers[] | .image' | sed 's/\"//g' >> /tmp/sts-images.txt

cat /dev/null > /tmp/ds-images.txt
cat /tmp/daemonset.json | jq '.items[] | .spec | .template | .spec | .containers[] | .image' | sed 's/\"//g' >> /tmp/ds-images.txt
cat /tmp/daemonset.json | jq '.items[] | .spec | .template | .spec | select(.initContainers) | .initContainers[] | .image' | sed 's/\"//g' >> /tmp/ds-images.txt

cat /dev/null > /tmp/images.txt
cat /tmp/deploy-images.txt >> /tmp/images.txt
cat /tmp/sts-images.txt >> /tmp/images.txt
cat /tmp/ds-images.txt >> /tmp/images.txt

cat /tmp/images.txt | sort | uniq > images.txt
