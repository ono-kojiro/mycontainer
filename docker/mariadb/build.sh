#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=./.env

if [ -e "${ENVFILE}" ]; then
  . ${ENVFILE}
else
  touch ${ENVFILE}
fi

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."

  target:
    help

    create
    start
    stop

    down
    attach
EOF
}

help()
{
  usage
}

full()
{
  create
  start
}

create()
{
  docker compose --env-file ${ENVFILE} up --no-start
}

start()
{
  docker compose --env-file ${ENVFILE} start
}

stop()
{
  docker compose --env-file ${ENVFILE} stop
}

restart()
{
  stop
  start
}

down()
{
  docker compose --env-file ${ENVFILE} down
}

attach()
{
  docker exec -it mariadb /bin/bash
}

ps()
{
  docker ps -a --no-trunc
}

all()
{
  usage
}

while [ "$#" -ne 0 ]; do
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

if [ "$#" -eq 0 ]; then
  all
fi

for target in "$@"; do
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done

