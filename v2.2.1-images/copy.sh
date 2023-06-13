#!/bin/bash
set -e

if [ -z ${SRC_DOMAIN} ]
then
  echo "environment variables not set"
  exit 1
fi

if [ -z ${DST_DOMAIN} ]
then
  echo "environment variables not set"
  exit 1
fi

function login() {
  if [ ! -z $SRC_PASSWORD ]
  then
    echo $SRC_PASSWORD | skopeo login $SRC_DOMAIN -u $SRC_USER --password-stdin
  fi
  if [ ! -z $DST_PASSWORD ]
  then
    echo $DST_PASSWORD | skopeo login $DST_DOMAIN -u $DST_USER --password-stdin
  fi
}

function create_project() {
  proj_name=$1
  cmd=$(curl -s -I "https://$DST_DOMAIN/api/v2.0/projects?project_name=$proj_name" \
      -H 'accept: application/json' \
      -w '%{http_code}\n' \
      -o /dev/null \
      -u $DST_USER:$DST_PASSWORD)

  if [ $cmd != 200 ]
  then
    cmd=$(curl -XPOST "https://$DST_DOMAIN/api/v2.0/projects" \
        -H "content-type: application/json" \
        -H "accept: application/json" \
        -u $DST_USER:$DST_PASSWORD \
        -d "{\"project_name\":\"$proj_name\",\"public\":false}")
    echo $cmd
  fi
}

function upload_to() {
  proj=$1
  create_project $proj

  while read target
  do
    skopeo copy docker://$SRC_DOMAIN/$proj/$target docker://$DST_DOMAIN/$proj/$target
  done < $proj/targets.txt
}

login
upload_to "library"
upload_to "cloudzcp"
upload_to "cloudzcp-addon"
upload_to "cloudzcp-public"
