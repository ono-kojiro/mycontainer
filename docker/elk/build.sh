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
  debfile="elasticsearch-${STACK_VER}-${STACK_ARCH}.deb"
  if [ ! -e "$debfile" ]; then
    wget https://artifacts.elastic.co/downloads/elasticsearch/$debfile
  else
    echo "skip download $debfile"
  fi

  debfile="kibana-${STACK_VER}-${STACK_ARCH}.deb"
  if [ ! -e "$debfile" ]; then
    wget https://artifacts.elastic.co/downloads/kibana/$debfile
  else
    echo "skip download $debfile"
  fi

}

build()
{
  docker build --tag elk .
}

create()
{
  docker compose --env-file ./env up --no-start
}

start()
{
  docker compose --env-file ./env start
}

ssh()
{
  command ssh localhost -p ${SSH_PORT}
}

attach()
{
  docker attach $container
}

status()
{
  docker ps -f name=$name
}

restart()
{
  stop
  start
}

test()
{
  test_http
}

stop()
{
  docker compose --env-file ./env stop
}

down()
{
  docker compose --env-file ./env down
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

