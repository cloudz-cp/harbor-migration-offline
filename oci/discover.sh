#!/bin/zsh
set -eo pipefail

# 레지스트리에 업로드된 이미지 목록을 가져온다.

DOMAIN="v2-zcr.cloudzcp.io"
USER=""
PASSWORD=""

clear_cache=false
enable_download=true

function login() {
  echo "Login harbor..."
  echo $PASSWORD | skopeo login $DOMAIN -u $USER --password-stdin
}

function count_repo_in() {
  proj=$1
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$proj/summary" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD)
  echo $cmd | jq -c '.repo_count' | sed 's/"//g'
}

function get_repo_list() {
  proj=$1
  page=$2
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$proj/repositories?page=$page&page_size=100" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD)
  echo $cmd | jq -c '.[] | .name' | sed 's/"//g' | sed "s/^$proj\///"
}

function get_repo_tags() {
  proj=$1
  repo=$2
  cmd=$(curl -s "https://$DOMAIN/api/v2.0/projects/$proj/repositories/$repo/artifacts" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD)
  echo $cmd | jq '.[] | if has("tags") then select(.tags) | .tags | .[] | .name else "latest" end' | sed 's/"//g'
}

function downloadTaggedRepo() {
  proj=$1
  repo=$2
  cmd=$(curl -s "https://$DOMAIN/api/repositories/$repo/tags/download" \
    -H "accept: application/json" \
    -u $USER:$PASSWORD \
    -o $repo.tar)
}

function make_artifact_targets_in() {
  proj=$1

  if [ ! -e $proj/repositories.txt ]
  then
    echo "No repositories.txt found. Creating new one..."
    num_of_repo=`count_repo_in $proj`
    total_pages=$((($num_of_repo+99)/100))
    echo "Found $num_of_repo repositories."

    tmp=`mktemp`
    for i in $(seq 1 $total_pages)
    do
      get_repo_list $proj $i >> $tmp
    done
    cat $tmp | sort | uniq  > $proj/repositories.txt
  fi

  if [ ! -e $proj/targets.txt ]
  then
    echo "No targets.txt found. Creating new one..."
    while read repo
    do
      encodedName=$(echo $repo | sed "s/\//%2F/g")
      tags=($(get_repo_tags $proj $encodedName))
      for tag in $tags
      do
        echo "$repo:$tag" >> $proj/targets.txt
      done
    done < $proj/repositories.txt
  fi
}


function download_targets() {
  proj=$1

  if [ ! -d $proj/download ]
  then
    mkdir -p $proj/download
  fi

  touch $proj/targets.txt
  cat /dev/null > $proj/failed.txt

  while read line
  do
    filename=$(echo $line | awk -F":" '{gsub(/\//, "_"); printf "%s+%s.tgz\n", $1, $2}')
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

function run() {
  proj=$1

  if [ "$clear_cache" = true ]
  then
    echo "clear $proj cache..."
    clear_cache $proj
  fi

  make_artifact_targets_in $proj

  if [ "$enable_download" = true ]
  then
    echo "download $proj targets"
    download_targets $proj
  fi
}

function clear_cache() {
  proj=$1
  rm -rf $proj/repositories.txt
  rm -rf $proj/targets.txt
  rm -rf $proj/failed.txt
}

function usage() {
    err_msg "Usage: $0 --refresh --dry-run --clear-cache"
    exit 1
}

function err_msg() { echo "$@" ;} >&2

while true; do
  case $1 in
    --dry-run)
      enable_download=false
      shift; continue
      ;;
    --refresh)
      clear_cache=true
      shift; continue
      ;;
    --clear-cache)
      clear_cache=true
      enable_download=false
      shift; continue
      ;;
    --*)
      err_msg "Invalid option: $1"
      usage;
      ;;
  esac
  break
done


login
for proj in "$@"
do
  run "$proj"
done
