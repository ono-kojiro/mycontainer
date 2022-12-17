#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

release="jammy"

image="$release"
container="$release"

root_url="https://partner-images.canonical.com/core/${release}/current/ubuntu-${release}-core-cloudimg-amd64-root.tar.gz"

root_filename=`basename $root_url`

help()
{
    usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    fetch
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

fetch()
{

  if [ ! -e "$root_filename" ]; then
    wget $root_url
  else
    echo "skip fetching $root_filename"
  fi
}

build()
{
  docker build --tag $image .
}

create()
{
  docker-compose up --no-start
}

status()
{
  ip addr show docker0
  docker network inspect bridge
}

start()
{
  docker-compose start
}

attach()
{
  docker attach $container
}

stop()
{
  docker-compose stop
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

