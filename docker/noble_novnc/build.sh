#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

release="noble"

image="${release}_novnc"
container="${release}_novnc"

envfile="./.env"

if [ -e "${envfile}" ]; then
  . ${envfile}
  flags="--env-file ${envfile}"
fi

help()
{
    usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    build
    create
    start
    stop
    ip
EOS
}

all()
{
  help
}

build()
{
  docker build --tag $image .
}

save()
{
  docker image save $image | xz -cz - > ${image}.tar.xz
}

load()
{
  cat ${image}.tar.xz | xz -d | docker load
}

create()
{
  docker compose $flags up --no-start
  ssl
}

ssl()
{
  docker cp novnc.crt noble_novnc:/etc/ssl/certs/server.crt
  docker cp novnc.key noble_novnc:/etc/ssl/private/server.key
}

start()
{
  docker compose $flags start
}

attach()
{
  docker exec -it ${CONTAINER_NAME} /bin/bash
}

ssh()
{
  command ssh -p ${SSH_LPORT} localhost
}

stop()
{
  docker compose $flags stop
}

down()
{
  docker compose $flags down
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ "$#" -ne 0 ]; do
  case "$1" in
    h)
      usage
	  ;;
    v)
      verbose=1
	  ;;
    *)
	  args="$args $1"
	  ;;
  esac

  shift

done

for target in $args ; do
  LANG=C type $target | grep function > /dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

