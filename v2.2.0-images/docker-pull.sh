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

function download_from() {
  proj=$1

  if [ ! -d $proj/download ]
  then
    mkdir -p $proj/download
  fi

  touch $proj/targets.txt
  cat /dev/null > $proj/failed.txt

  while read line
  do
    echo "Pull $DOMAIN/$proj/$line"
    set +eo pipefail
    docker pull $DOMAIN/$proj/$line
    if [ $? -ne 0 ]
    then
      echo "$line" >> $proj/failed.txt
    fi
    set -eo pipefail
  done < $proj/targets.txt
}

login
download_from "library"
download_from "cloudzcp"
download_from "cloudzcp-addon"
download_from "cloudzcp-public"