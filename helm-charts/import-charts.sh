#!/bin/zsh
set -eo pipefail

DOMAIN="ngs-registry.pps-poc.cloudzcp.net"
USER=""
PASSWORD=""

function create_project() {
  proj_name=$1
  cmd=$(curl -s -I "https://$DOMAIN/api/v2.0/projects?project_name=$proj_name" \
      -H 'accept: application/json' \
      -w '%{http_code}\n' \
      -o /dev/null \
      -u $USER:PASSWORD)

  if [ $cmd != 200 ]
  then
    cmd=$(curl -XPOST "https://$DOMAIN/api/v2.0/projects" \
        -H "content-type: application/json" \
        -H "accept: application/json" \
        -u $USER:PASSWORD \
        -d "{\"project_name\":\"$proj_name\",\"public\":false}")
    echo $cmd
  fi
}

# https://github.com/chartmuseum/helm-push
function upload_chart_to() {
  proj=$1
  create_project $proj
  while read target
  do
    helm cm-push $proj/download/$target https://$DOMAIN/chartrepo/$proj \
      --username $USER \
      --password $PASSWORD
  done < $proj/targets.txt
}

upload_chart_to "cloudzcp"
upload_chart_to "cloudzcp-addon"