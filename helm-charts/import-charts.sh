#!/bin/zsh
set -eo pipefail

DOMAIN="tta-registry.gs.cloudzcp.net"
UPLOAD_USER=""
UPLOAD_USER_PASS=""

# https://github.com/chartmuseum/helm-push
function uploads() {
  proj=$1
  while read target
  do
    helm cm-push $proj/download/$target https://$DOMAIN/chartrepo/$proj \
      --username $UPLOAD_USER \
      --password $UPLOAD_USER_PASS
  done < $proj/targets.txt
}

#uploads "cloudzcp"
uploads "cloudzcp-addon"