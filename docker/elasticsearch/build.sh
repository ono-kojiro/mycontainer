#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    prepare
    create
    start

    get
    patch
    put

    stop

    down
    destroy
EOS
}

all()
{
  help
}

prepare()
{
  sudo mkdir -p /var/lib/elasticsearch
  sudo mkdir -p /var/lib/elasticsearch/certs
  sudo mkdir -p /var/lib/elasticsearch/data
  sudo mkdir -p /var/lib/elasticsearch/etc

  sudo cp -f elasticsearch.crt /var/lib/elasticsearch/certs/
  sudo cp -f elasticsearch.key /var/lib/elasticsearch/certs/
  sudo cp -f mylocalca.pem     /var/lib/elasticsearch/certs/
  
  sudo chown -R 1000:1000 /var/lib/elasticsearch
  
  sudo mkdir -p /var/lib/kibana
  sudo mkdir -p /var/lib/kibana/config/certs
  sudo cp    -f mylocalca.pem     /var/lib/kibana/config/certs/
  sudo cp    -f kibana.yml        /var/lib/kibana/config/
  sudo chown -R 1000:1000 /var/lib/kibana
  
}

restart()
{
  stop
  start
}

pull()
{
  docker cp kibana:/usr/share/kibana/config/kibana.yml .
}

push()
{
  docker cp kibana.yml kibana:/usr/share/kibana/config/kibana.yml
  docker exec --user kibana kibana mkdir -p /usr/share/kibana/config/certs/
  docker exec --user root kibana chown -R 1000:1000 /usr/share/kibana/config/certs/
  docker cp mylocalca.pem     kibana:/usr/share/kibana/config/certs/
}

passwd()
{
   echo "Setting kibana_system password";
   curl -s \
     -X POST --cacert mylocalca.pem \
     -u "elastic:elastic" \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/_security/user/kibana_system/_password \
     -d "{ \"password\":\"elastic\" }"
}

debug()
{
  docker cp kibana:/usr/share/kibana/logs/kibana.log .
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
}

es()
{
  docker exec -it --user root elasticsearch /bin/bash
}

kibana()
{
  docker exec -it --user root kibana /bin/bash
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

destroy()
{
  sudo rm -rf /var/lib/elasticsearch
  sudo rm -rf /var/lib/kibana
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

