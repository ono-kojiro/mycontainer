#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

if [ -e "./.env" ]; then
  . ./.env
fi

image="${IMAGE}"
container_name="${CONTAINER_NAME}"

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

network()
{
  docker network create -d macvlan \
    --subnet=192.168.20.0/24 \
    --gateway=192.168.20.1 \
    -o parent=macvlan0 \
    macvlan1
}

create()
{
  docker compose up --no-start
}

status()
{
  ip addr show docker0
  docker network inspect bridge
}

start()
{
  docker compose start
}

attach()
{
  docker exec -it $container_name /bin/bash
}

ssh()
{
  command ssh -p ${SSH_LPORT} localhost
}

stop()
{
  docker compose stop
}

down()
{
  docker compose down
}

ip()
{
  docker inspect \
    --format '{{.Name}} {{ .NetworkSettings.IPAddress }}' \
	$(docker ps -q)
}

if [ "$#" = "0" ]; then
  usage
  exit 1
fi

args=""

while [ "$#" != "0" ]; do
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
  if [ "$?" = "0" ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

