#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

. ./env
extra_vars=`cat env | tr '\n' ' '`

DOWNLOAD_DIR=/opt/greenbone-community-container

help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    create
    start
    down
    destroy
EOS
}

all()
{
  help
}

prepare()
{
  if [ ! -e "$DOWNLOAD_DIR" ]; then
    sudo mkdir -p $DOWNLOAD_DIR
  fi
  cd $DOWNLOAD_DIR
  curl -f -L https://greenbone.github.io/docs/latest/_static/docker-compose-22.4.yml \
    -o docker-compose.yml
  cd $top_dir
}

pull()
{
  docker compose -f $DOWNLOAD_DIR/docker-compose.yml -p greenbone-community-edition pull
}

create()
{
  docker compose \
    -f $DOWNLOAD_DIR/docker-compose.yml \
    -p greenbone-community-edition up --no-start
}

start()
{
  docker compose \
    -f $DOWNLOAD_DIR/docker-compose.yml \
    -p greenbone-community-edition start
}

ssh()
{
  command ssh localhost -p ${SSH_PORT}
}

attach()
{
  docker exec -it greenbone-community-edition-gvmd-1 /bin/bash
}

passwd()
{
  docker compose \
    -f $DOWNLOAD_DIR/docker-compose.yml \
    -p greenbone-community-edition \
    exec -u gvmd gvmd gvmd --user=admin --new-password=secret
}


status()
{
  docker ps -f name=${NAME}
}

restart()
{
  stop
  start
}

stop()
{
  docker compose \
    -f $DOWNLOAD_DIR/docker-compose.yml \
    -p greenbone-community-edition stop
}

down()
{
  docker compose \
    -f $DOWNLOAD_DIR/docker-compose.yml \
    -p greenbone-community-edition down
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    -h )
      usage
	  ;;
    -v )
      verbose=1
	  ;;
    *)
	  args="$args $1"
	  ;;
  esac

  shift

done

for target in $args ; do
  num=`LANG=C type $target 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

