#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name=elasticsearch
     
username=`cat netrc | grep login | awk '{ print $2 }'`
password=`cat netrc | grep password | awk '{ print $2 }'`

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

    chpasswd
    restart

    test_simple, test_http, test_https
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
  ES_VER=8.6.2
  ES_ARCH=amd64
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ES_VER-$ES_ARCH.deb
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
}

stop()
{
  docker compose stop
}

down()
{
  docker compose down
}



deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

reset()
{
  ansible-playbook -K -i hosts.yml reset.yml
}

test_https()
{
   echo "test https"
   curl -k \
     -u "$username:$password" \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/
}

test_simple()
{
   curl -k \
     -u "$username:$password" \
     https://192.168.0.98:9200/ 
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

