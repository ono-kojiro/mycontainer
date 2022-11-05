#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

image="postgres-ssl"
tag="14.5-alpine3.16-ssl"
container="$image"

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
    connect
    stop
    destroy
EOS

}

all()
{
  build
  create
  start
}

build()
{
  docker build --tag $image:$tag --no-cache .
}

create()
{
  docker-compose up --no-start
}

start()
{
  docker-compose start
}

status()
{
  docker ps -a
}

attach()
{
  docker exec -it $container /bin/bash
}

initdb()
{
  docker exec -i $container /bin/bash << EOS

ps -ef
psql -h localhost -u
EOS
  
}

connect()
{
  PGSSLROOTCERT=$HOME/.local/share/mkcert/rootCA.pem psql \
    -h localhost -p 15432 sampledb $USER
}

stop()
{
  docker-compose stop
}

destroy()
{
  docker-compose down
  docker rmi $(docker images -q $image)
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

