#!/bin/zsh
set -eo pipefail

DOMAIN="v2-zcr.cloudzcp.io"
USER=""
PASSWORD=""

function loginHarbor() {
  echo $PASSWORD | skopeo login $DOMAIN -u $USER --password-stdin
}

function listRepo() {
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$1/repositories?page=1&page_size=100" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD)
  echo $cmd | jq -c '.[] | .name' | sed 's/"//g' | sed "s/^$1\///"
}

function getTags() {
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$1/repositories/$2/artifacts" \
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
  if [ ! -e $proj/targets.txt ]
  then
    cat /dev/null > $proj/targets.txt
    repos=($(listRepo $proj))
    for repo in $repos
    do
      encodedName=$(echo $repo | sed "s/\//%2F/g")
      tags=($(getTags $proj $encodedName))
      for tag in $tags
      do
        echo "$repo:$tag" >> $proj/targets.txt
      done
    done
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
downloadTaggedRepo "cloudzcp-public"
downloadTaggedRepo "cloudzcp-addon"