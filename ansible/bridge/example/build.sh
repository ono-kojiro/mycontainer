#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

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
    stop
EOS
}

all()
{
  create
  start
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
}

attach0()
{
  docker exec -it server /bin/bash
}

attach1()
{
  docker exec -it client1 /bin/bash
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
  if [ "$?" = "0" ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

