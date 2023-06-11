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
    prepare
    create
    start

    get
    patch
    put

    stop

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
  sudo mkdir -p /var/lib/elasticsearch
  sudo mkdir -p /var/lib/elasticsearch/certs
  sudo mkdir -p /var/lib/elasticsearch/data
  sudo mkdir -p /var/lib/elasticsearch/etc

  sudo chown -R 1000:1000 /var/lib/elasticsearch
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
}

attach()
{
  docker exec -it --user root elasticsearch /bin/bash
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

destroy()
{
  sudo rm -rf /var/lib/elasticsearch
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
  LANG=C type $target | grep function > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

