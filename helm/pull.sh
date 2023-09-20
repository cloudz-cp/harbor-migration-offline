#!/bin/zsh
set -eo pipefail

if [ -z ${DOMAIN}  ] || [ -z ${USER} ] || [ -z ${PASSWORD} ]
then
  echo "environment variables not set"
  exit 1
fi

function login() {
  echo $PASSWORD | skopeo login $DOMAIN -u $USER --password-stdin
}

function add_helm_repo() {
  proj=$1
  set +eo pipefail
  helm repo ls -o json | jq '.[] | .name' | sed 's/"//g' | grep -x -q "$proj"
  if [ $? -eq 1 ]
  then
    echo "Add new repo: https://$DOMAIN/chartrepo/$proj"
    set -eo pipefail
    helm repo add $proj "https://$DOMAIN/chartrepo/$proj" \
      --username $USER \
      --password $PASSWORD
  else
    echo "Skip already added repo: $proj"
  fi
  helm repo update $proj
  set -eo pipefail
}

function list_chart_from() {
  proj=$1
  cmd=$(helm search repo "$proj/" -o json)
  echo $cmd | jq ".[] | .name | sub(\"$proj/\"; \"\")" | sed 's/"//g'
}

function get_chart_version() {
  proj=$1
  chart=$2
  cmd=$(helm search repo $proj/$chart -l -o json)
  echo $cmd | jq ".[] | select(.name==\"$proj/$chart\") | .version" | sed 's/"//g'
}

function download() {
  proj=$1
  file=$2
  dest=$3
  curl -s "https://$DOMAIN/chartrepo/$proj/charts/$file" \
    -u $USER:$PASSWORD \
    -o $dest
}

function download_chart_from() {
  proj=$1
  add_helm_repo "$proj"

  if [ ! -d "$proj/download" ]
  then
    mkdir -p "$proj/download"
  fi

  if [ ! -e "$proj/targets.txt" ]
  then
    charts=($(list_chart_from "$proj"))
    for c in $charts
    do
      versions=($(get_chart_version $proj $c))
      for v in $versions
      do
        echo "$c-$v.tgz" >> $proj/targets.txt
      done
    done
  fi

  while read target
  do
    echo "Download $target to $proj/download/$target"
    download $proj $target $proj/download/$target
  done < $proj/targets.txt
}

login
download_chart_from "cloudzcp"
download_chart_from "cloudzcp-addon"
