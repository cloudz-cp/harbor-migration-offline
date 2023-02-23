#!/bin/zsh
set -eo pipefail

REGISTRY="v2-zcr.cloudzcp.io"
REGISTRY_USER=""
REGISTRY_PASSWORD=""

function login () {
  echo $REGISTRY_PASSWORD | skopeo login $REGISTRY -u $REGISTRY_USER --password-stdin
}

function replicate_to() {
  proj=$1

  while read line
  do
    img=$(echo $line | sed -e "s/^docker.io\///" -e "s/^quay.io\///" -e "s/^ghcr.io\///" )
    echo "Replicate $line to $REGISTRY/$proj/$img"
    set +eo pipefail
    skopeo copy --override-os linux --override-arch amd64 docker://$line docker://$REGISTRY/$proj/$img
    if [ $? -ne 0 ]
    then
      echo "$line" >> $proj/failed.txt
    fi
    set -eo pipefail
  done < $proj/extras.txt
}

login $REGISTRY
replicate_to "cloudzcp-public"