#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

es_ver=8.9.2
es_arch=amd64

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
  debfile="elasticsearch-${es_ver}-${es_arch}.deb"
  wget \
    https://artifacts.elastic.co/downloads/elasticsearch/${debfile}
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
}

status()
{
  docker ps -a | grep elk
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
  #ansible-playbook -K -i hosts.yml reset.yml
  ssh -t elk \
    sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password \
        -u elastic --silent --batch
}

gennetrc()
{
  ssh -t elk \
    sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password \
        -u elastic --silent --batch | tee tmp.log

  sed -i -e 's|||' tmp.log
  newpass=`cat tmp.log | grep -v -F '[sudo]'`
  #rm -f tmp.log

  {
    echo "machine 192.168.0.98"
    echo "login   elastic"
    echo "password $newpass"
    echo ""
  } > netrc
}

test_https()
{
   echo "test https"
   curl -k \
     --netrc-file netrc \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/
}

test_simple()
{
   curl -k \
     --netrc-file netrc \
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

