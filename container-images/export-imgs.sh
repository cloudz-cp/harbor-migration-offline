#!/bin/zsh
set -eo pipefail

DOMAIN="v2-zcr.cloudzcp.io"
USER=""
PASSWORD=""

function loginHarbor() {
  echo $PASSWORD | skopeo login $DOMAIN -u $USER --password-stdin
}

function countRepo() {
  proj=$1
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$proj/summary" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD)
  echo $cmd | jq -c '.repo_count' | sed 's/"//g'
}

function listRepo() {
  proj=$1
  page=$2
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$proj/repositories?page=$page&page_size=100" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD)
  echo $cmd | jq -c '.[] | .name' | sed 's/"//g' | sed "s/^$proj\///"
}

function getTags() {
  proj=$1
  repo=$2
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$proj/repositories/$repo/artifacts" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD)
  echo $cmd | jq '.[] | if has("tags") then select(.tags) | .tags | .[] | .name else "latest" end' | sed 's/"//g'
}

function downloadTaggedRepo() {
  proj=$1

  if [ ! -d $proj/download ]
  then
    mkdir -p $proj/download
  fi

  if [ ! -e $proj/repositories.txt ]
  then
    pages=$((($(countRepo cloudzcp-public)+99)/100))
    for i in $(seq 1 $pages)
    do
      listRepo $proj $i >> $proj/repositories.txt
    done
  fi

  if [ ! -e $proj/targets.txt ]
  then
    while read repo
    do
      encodedName=$(echo $repo | sed "s/\//%2F/g")
      tags=($(getTags $proj $encodedName))
      for tag in $tags
      do
        echo "$repo:$tag" >> $proj/targets.txt
      done
    done < $proj/repositories.txt
  fi

  while read line
  do
    filename=$(echo $line | awk -F":" '{gsub(/\//, "_"); printf "%s+%s.tgz\n", $1, $2}')
    if [ -e $proj/download/$filename ]
    then
      echo "Already downloaded image ($filename)"
      continue
    fi
    echo "Download $DOMAIN/$proj/$line to $proj/download/$filename"
    skopeo copy -q --dest-compress-format gzip docker://$DOMAIN/$proj/$line docker-archive:$proj/download/$filename:$line
  done < $proj/targets.txt
}

loginHarbor
downloadTaggedRepo "cloudzcp"
downloadTaggedRepo "cloudzcp-addon"
downloadTaggedRepo "cloudzcp-public"
