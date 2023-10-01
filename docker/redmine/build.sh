#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

. ./env

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."

  target:
    help

    create
    enable_ssl
    start
    stop

    fetch
    patch
    upload

    debug
    ps
    down
EOF
}

help()
{
  usage
}

create()
{
  docker compose --env-file ./env up --no-start
}

start()
{
  docker compose --env-file ./env start
}

stop()
{
  docker compose --env-file ./env stop
}

restart()
{
  stop
  start
}

down()
{
  docker compose --env-file ./env down
}

attach()
{
  docker exec -it ${CONTAINER_NAME} /bin/bash
}

enable_ssl()
{
  files="redmine.crt redmine.key"
  for file in $files; do
    docker cp $file ${CONTAINER_NAME}:/usr/src/redmine/config/
  done
}

fetch()
{
  files=""
  files="$files config/environment.rb"
  files="$files config.ru"

  for file in $files; do
    echo "fetch $file ..."
    docker cp ${CONTAINER_NAME}:/usr/src/redmine/$file .
  done
}

patch()
{
  command patch -p1 -i 0000-change_prefix.patch
}

upload()
{
  # config.ru, environment.rb

  files=""
  files="$files environment.rb"
  
  for file in $files; do
    docker cp $file ${CONTAINER_NAME}:/usr/src/redmine/config/
  done
  
  filename="config.ru"
  if [ -e "$filename" ]; then  
    docker cp $filename ${CONTAINER_NAME}:/usr/src/redmine/
  fi
}

config()
{
  upload
}

ps()
{
  docker ps -a --no-trunc
}

all()
{
  usage
}

while [ $# -ne 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  all
fi

for target in "$@"; do
  LANG=C type "$target" | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done

