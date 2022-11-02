#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

release="jammy"

image="$release"
container="$release"

case $release in
  bionic )
    root_url="https://partner-images.canonical.com/core/bionic/current/ubuntu-bionic-core-cloudimg-amd64-root.tar.gz"
    ;;
  focal )
    root_url="https://partner-images.canonical.com/core/focal/current/ubuntu-focal-core-cloudimg-amd64-root.tar.gz"
    ;;
  jammy )
    root_url="https://partner-images.canonical.com/core/$release/current/ubuntu-$release-core-cloudimg-amd64-root.tar.gz"
    ;;
esac

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
  #docker create \
  #  -it \
  # --hostname $container \
  # --env TZ=Asia/Tokyo \
  # --name $container \
  # $image
}

start()
{
  #docker start $container
  docker-compose start
}

attach()
{
  docker attach $container
}

stop()
{
  # docker stop $container
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

