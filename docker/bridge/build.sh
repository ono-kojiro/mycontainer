#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

# https://qiita.com/ttsubo/items/40162f5001a8c95040d9

name="mybridge"
subnet="192.168.10.0/24"
gateway="192.168.10.1"
device="br0"

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
    ls
    remove
EOS
}

all()
{
  help
}

create()
{
  docker network create \
    --driver=bridge \
    --subnet=$subnet \
    --gateway=$gateway \
    --opt "com.docker.network.bridge.name"="$device" \
    $name
}

ls()
{
  docker network ls
}

remove()
{
  docker network remove $name
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

