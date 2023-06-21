#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

image="gitbucket"
name="${image}"

docker_compose="docker compose"

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
  $docker_compose pull
}

pull()
{
  fetch
}

build()
{
  docker build -t ${name} .
}

prepare()
{
  sudo mkdir -p /var/lib/gitbucket
}

create()
{
  $docker_compose up --no-start
}

copy()
{
  docker cp startup.sh gitbucket:/
  docker cp gitbucket.jks gitbucket:/var/lib/gitbucket/
  #docker cp server.p12 gitbucket:/var/lib/gitbucket/
}

status()
{
  #ip addr show docker0
  #docker network inspect bridge
  docker ps -a | grep gitbucket
}

log()
{
  docker cp gitbucket:/var/lib/gitbucket/gitbucket.log .
}

start()
{
  $docker_compose start
}

attach()
{
  docker exec -it $name /bin/bash
}

ssh()
{
  command ssh -p 22040 localhost
}

stop()
{
  $docker_compose stop
}

down()
{
  $docker_compose down
}

ip()
{
  docker inspect \
    --format '{{.Name}} {{ .NetworkSettings.IPAddress }}' \
	$(docker ps -q)
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

