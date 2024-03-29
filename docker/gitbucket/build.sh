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
    create
    update
    start
    stop
    start
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

update()
{
  copy_startup
  copy_jks
  copy_config
}

copy_startup()
{
  echo "copy startup.sh to container"
  docker cp startup.sh gitbucket:/
}

copy_config()
{
  echo "copy gitbucket.conf to container"
  docker cp gitbucket.conf gitbucket:/gitbucket/
}


copy_jks()
{
  echo "copy gitbucket.jks to gitbucket:/gitbucket/"
  docker cp gitbucket.jks gitbucket:/gitbucket/
}

import_cacert()
{
  cacert="myca.crt"
  caname="myca"

  docker cp $cacert gitbucket:/gitbucket/
  docker exec --user root ${name} \
    keytool -importcert -trustcacerts \
    -keystore /opt/java/openjdk/lib/security/cacerts \
    -storepass changeit \
    -noprompt \
    -alias $caname \
    -file /gitbucket/$cacert
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
  docker exec -it --user 0 $name /bin/bash
}

ssh()
{
  command ssh -p 22040 localhost
}

stop()
{
  $docker_compose stop
}

restart()
{
  $docker_compose stop
  $docker_compose start
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

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

destroy()
{
  sudo rm -rf /var/lib/gitbucket/
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

