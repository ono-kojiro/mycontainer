#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

release="bookworm"

image="$release"
container="$release"

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
  docker exec -it $container /bin/bash
}

ssh()
{
  command ssh -p 12022 localhost
}

stop()
{
  docker compose stop
}

down()
{
  docker compose down
}

if [ "$#" -eq 0 ]; then
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

