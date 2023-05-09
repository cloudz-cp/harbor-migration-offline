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
  local proj=$1

  if [ ! -d $proj/download ]
  then
    mkdir -p $proj/download
  fi

  touch $proj/targets.txt
  cat /dev/null > $proj/failed.txt

  while read line
  do
    local filename=$(echo $line | awk -F":" '{gsub(/\//, "_"); printf "%s+%s.tgz\n", $1, $2}')
    if [ -e $proj/download/$filename ]
    then
      echo "Already downloaded image: $filename"
      continue
    fi

    echo "Download $DOMAIN/$proj/$line to $proj/download/$filename"
    set +eo pipefail
    skopeo copy -q --override-os linux --override-arch amd64 --dest-compress-format gzip \
      docker://$DOMAIN/$proj/$line oci-archive:$proj/download/$filename:$line

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