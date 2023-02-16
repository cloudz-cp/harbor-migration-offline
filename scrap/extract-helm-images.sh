#!/bin/zsh

export KUBECONFIG=$HOME/Workspace/jodalchung/.kube/config

DOMAIN=v2-zcr.cloudzcp.io
charts=$(helm ls -A | tail -n +2 | awk '{printf("%s,%s,%s\n", $1, $2, $9)}')

cat /dev/null > collect.txt

while IFS=',' read -r release namespace chart;
do
  manifest=$(helm get manifest $release -n $namespace)
  images=($(echo $manifest | grep "image:" | sed 's/\"//g' | sed 's/^[\ |-]*image:\ //' | sort | uniq))
  for img in $images
  do
    name=$(echo $img | sed "s/$DOMAIN\///")
    echo "$chart,$name" >> collect.txt
  done
done <<< $charts

cat collect.txt | sort | uniq > chart-images.txt
