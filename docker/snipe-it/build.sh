#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=./.env

if [ -e "${ENVFILE}" ]; then
  . ${ENVFILE}
fi

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."

  target:
    help

    create

    enable_ssl
    fetch
    patch
    upload

    start
    stop


    debug
    ps
    down
EOF
}

help()
{
  usage
}

fetch()
{
  curl -O https://raw.githubusercontent.com/snipe/snipe-it/master/docker-compose.yml
  curl --output .env https://raw.githubusercontent.com/snipe/snipe-it/master/.env.docker

}

update()
{
  sed -ie "s/APP_VERSION=\(.*\)/APP_VERSION=v8.3.7-alpine/" .env
  sed -ie "s|APP_URL=\(.*\)|APP_URL=http://192.168.1.72:8000|" .env
  sed -ie "s/APP_TIMEZONE='UTC'/APP_TIMEZONE='JST'/" .env
  sed -ie "s/APP_LOCALE=en-US/APP_LOCALE=ja-JP/" .env

  sed -ie "s/DB_PASSWORD=\(.*\)/DB_PASSWORD=mypasswd/" .env
  sed -ie "s/MYSQL_ROOT_PASSWORD=\(.*\)/MYSQL_ROOT_PASSWORD=mypasswd/" .env
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

destroy()
{
  down
  docker volume rm snipe-it_db_data
  docker volume rm snipe-it_storage
}

attach()
{
  docker exec -it snipe-it-app-1 /bin/sh
}

attach_db()
{
  docker exec -it snipe-it-db-1 /bin/bash
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

