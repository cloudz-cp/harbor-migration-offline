#!/bin/zsh
set -e

DOMAIN="tta-registry.gs.cloudzcp.net"
USER=""
PASSWORD=""

function login() {
#  echo $PASSWORD | skopeo login $DOMAIN -u $USER --password-stdin
  echo $PASSWORD | docker login $DOMAIN -u $USER --password-stdin
}

function createProjectIfNotExist() {
  proj_name=$1
  cmd=$(curl -s -I "https://$DOMAIN/api/v2.0/projects?project_name=$proj_name" \
      -H 'accept: application/json' \
      -w '%{http_code}\n' \
      -o /dev/null \
      -u $USER:$PASSWORD)

  if [ $cmd != 200 ]
  then
    cmd=$(curl -XPOST "https://$DOMAIN/api/v2.0/projects" \
        -H "content-type: application/json" \
        -H "accept: application/json" \
        -u $USER:$PASSWORD \
        -d "{\"project_name\":\"$proj_name\",\"public\":false}")
    echo $cmd
  fi
}

function upload() {
  proj=$1
  createProjectIfNotExist $proj
  while read target
  do
    tgz=$(echo $target | awk -F":" '{gsub(/\//, "_"); printf "%s+%s.tgz\n", $1, $2}')
    echo "Upload '$proj/download/$tgz' to $DOMAIN/$proj/$target"
#    skopeo copy oci-archive:$proj/download/$tgz docker://$DOMAIN/$proj/$target
    docker image load --input $proj/download/$tgz
    docker tag $target $DOMAIN/$proj/$target
    docker push $DOMAIN/$proj/$target
  done < $proj/targets.txt
}

login
upload "cloudzcp"
upload "cloudzcp-addon"
upload "cloudzcp-public"
