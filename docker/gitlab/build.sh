#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="gitlab"

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
  destroy
  init

  sudo mkdir -p /etc/gitlab/ssl
  sudo cp -f $HOME/.local/share/gitlab/gitlab.crt /etc/gitlab/ssl/
  sudo cp -f $HOME/.local/share/gitlab/gitlab.key /etc/gitlab/ssl/

  create
  start
}

fetch()
{
  docker compose pull
}

pull()
{
  fetch
}

build()
{
  docker build -t ${name} .
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
  #docker attach ${name}
  docker exec -it ${name} /bin/bash
}

ssh()
{
  command ssh -p 22040 localhost
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

init()
{
  sudo mkdir -p /etc/gitlab
  sudo mkdir -p /var/log/gitlab
  sudo mkdir -p /var/lib/gitlab
  sudo mkdir -p /var/opt/gitlab
}


destroy()
{
  sudo rm -rf /etc/gitlab
  sudo rm -rf /var/log/gitlab
  sudo rm -rf /var/lib/gitlab
  sudo rm -rf /var/opt/gitlab
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

