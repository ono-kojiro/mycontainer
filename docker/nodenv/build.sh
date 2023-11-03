#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

. ./env
extra_vars=`cat env | tr '\n' ' '`

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

fetch()
{
  if [ ! -e "v5.25.0.tar.gz" ]; then
    wget https://github.com/vega/vega/archive/refs/tags/v5.25.0.tar.gz
  fi

  filename="v4.9.129.tar.gz"
  url="https://github.com/nodenv/node-build/archive/refs/tags/$filename"
  if [ ! -e "$filename" ]; then
    curl -O $filename $url
  fi
}

create()
{
  docker compose --env-file ./env up --no-start
}

start()
{
  docker compose --env-file ./env start
}

stop()
{
  docker compose --env-file ./env stop
}

restart()
{
  stop
  start
}

down()
{
  docker compose --env-file ./env down
}

deploy()
{
  ansible-playbook -i hosts.yml site.yml
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

