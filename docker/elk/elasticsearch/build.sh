#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

es_ver=8.9.2
es_arch=amd64

name=elasticsearch
     
help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    deploy
    reset
    check

    test_http, test_https
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
  ssh -t elk \
    sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password \
        -u elastic --silent --batch | tee elastic.log
  
  sed -i -e 's|||' elastic.log
  es_pass=`cat elastic.log | grep -v -F '[sudo]'`

  {
    echo "machine  192.168.0.98"
    echo "login    elastic"
    echo "password $es_pass"
  } > netrc

  rm -f elastic.log

  echo "password of user 'elastic' is saved in ./netrc"
}

gennetrc()
{
  ssh -t elk \
    sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password \
        -u elastic --silent --batch | tee elastic.log
  
  ssh -t elk \
    sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password \
        -u kibana_system --silent --batch | tee kibana_system.log

  sed -i -e 's|||' elastic.log
  es_pass=`cat elastic.log | grep -v -F '[sudo]'`
  
  sed -i -e 's|||' kibana_system.log
  kb_pass=`cat kibana_system.log | grep -v -F '[sudo]'`

  {
    echo "machine  192.168.0.98"
    echo "login    elastic"
    echo "password $es_pass"
    echo ""
    echo "machine  192.168.0.98"
    echo "login    kibana_system"
    echo "password $kb_pass"
    echo ""
  } > netrc

  rm -f elastic.log kibana_system.log
}

test_https()
{
   echo "test https"
   curl -k \
     --netrc-file netrc \
     https://192.168.0.98:9200/
}

test_http()
{
   echo "test http"
   curl -k \
     --netrc-file netrc \
     https://192.168.0.98:9200/ 
}

check()
{
  #test_http
  test_https
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

