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
    prepare
    create
    enable_https

    start
    (configure ldap auth...)
    stop

    enable_ldaps
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

enable_https()
{
  docker cp startup.sh gitbucket:/
  docker cp gitbucket.jks gitbucket:/var/lib/gitbucket/
}

enable_ldaps()
{
  docker cp mylocalca.pem gitbucket:/var/lib/gitbucket/
  docker exec --user root ${name} \
    keytool -import -trustcacerts \
    -keystore /opt/java/openjdk/lib/security/cacerts \
    -storepass changeit \
    -noprompt \
    -alias mylocalca \
    -file /var/lib/gitbucket/mylocalca.pem
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

