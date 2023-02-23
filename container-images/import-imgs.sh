#!/bin/zsh
set -e

DOMAIN=""
USER=""
PASSWORD=""

function login() {
  echo $PASSWORD | skopeo login $DOMAIN -u $USER --password-stdin
}

function create_project() {
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

function upload_to() {
  proj=$1
  create_project $proj
  while read target
  do
    name=$(echo $target | awk -F":" '{gsub(/\//, "_"); printf "%s+%s.tgz\n", $1, $2}')
    echo "Upload '$proj/download/$name' to $DOMAIN/$proj/$target"
    skopeo copy oci-archive:$proj/download/$name docker://$DOMAIN/$proj/$target
  done < $proj/targets.txt
}

login
upload_to "cloudzcp"
upload_to "cloudzcp-public"
upload_to "cloudzcp-addon"