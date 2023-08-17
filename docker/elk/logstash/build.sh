#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

LS_VER=8.9.0
LS_ARCH=amd64

username="elastic"
password="MvRIiqh1+f8Vp5Ha5Oqu"

help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    destroy
EOS
}

all()
{
  help
}

fetch()
{
  LS_VER=8.9.0
  LS_ARCH=amd64
  wget https://artifacts.elastic.co/downloads/logstash/logstash-$LS_VER-$LS_ARCH.deb
}

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
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
   curl \
     -X GET --cacert mylocalca.pem \
     -u "kibana_system:elastic" \
     -H "Content-Type: application/json" \
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

