#!/bin/zsh
set -eo pipefail

REGISTRY="tta-registry.gs.cloudzcp.net"
REGISTRY_USER="cloudzcp-admin"
REGISTRY_PASSWORD="0tsKZpJens3yYTbiuaZU0Zt1RPwK4XwL"

function login_registry () {
  echo $REGISTRY_PASSWORD | skopeo login $REGISTRY -u $REGISTRY_USER --password-stdin
}

function replicate_extras() {
  proj=$1
  while read line
  do
    img=$(echo $line | sed -e "s/^docker.io\///" -e "s/^quay.io\///" )
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

login_registry $REGISTRY
replicate_extras "cloudzcp-public"