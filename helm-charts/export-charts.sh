#!/bin/zsh
set -eo pipefail

DOMAIN="v2-zcr.cloudzcp.io"
USER=""
PASSWORD=""

function loginHarbor() {
  echo $PASSWORD | skopeo login $DOMAIN -u $USER --password-stdin
}

function addHelmRepo() {
  proj=$1
  set +eo pipefail
  helm repo ls -o json | jq '.[] | .name' | sed 's/"//g' | grep -x -q "$proj"
  if [ $? -eq 1 ]
  then
    echo "Add new repo: https://v2-zcr.cloudzcp.io/chartrepo/$proj"
    set -eo pipefail
    helm repo add $proj "https://v2-zcr.cloudzcp.io/chartrepo/$proj" \
      --username $USER \
      --password $PASSWORD
  else
    echo "Skip already added repo: $proj"
  fi
  set -eo pipefail
}

function getCharts() {
  proj=$1
  cmd=$(helm search repo "$proj/" -o json)
  echo $cmd | jq ".[] | .name | sub(\"$proj/\"; \"\")" | sed 's/"//g'
}

function getVersions() {
  chart=$1
  cmd=$(helm search repo "$chart" -l -o json)
  echo $cmd | jq '.[] | .version' | sed 's/"//g'
}

function download() {
  proj=$1
  file=$2
  dest=$3
  curl -s "https://$DOMAIN/chartrepo/$proj/charts/$file" \
    -u $USER:$PASSWORD \
    -o $dest
}

function downloadCharts() {
  proj=$1

  addHelmRepo "$proj"
  if [ ! -d "$proj/download" ]
  then
    mkdir -p "$proj/download"
  fi

  if [ ! -e "$proj/targets.txt" ]
  then
    charts=($(getCharts "$proj"))
    for c in $charts
    do
      versions=($(getVersions $c))
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

loginHarbor
downloadCharts "cloudzcp"
downloadCharts "cloudzcp-addon"
downloadCharts "cloudzcp-public"

