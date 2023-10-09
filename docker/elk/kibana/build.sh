#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

KB_VER=8.10.2
KB_ARCH=amd64

help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    reset
    deploy
    check
EOS
}

all()
{
  help
}

fetch()
{
  KB_ARCH=amd64
  wget https://artifacts.elastic.co/downloads/kibana/kibana-$KB_VER-$KB_ARCH.deb
}

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

reset()
{
  ssh -t elk \
    sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password \
        -u kibana_system --silent --batch | tee kibana.log
  
  sed -i -e 's|||' kibana.log
  es_pass=`cat kibana.log | grep -v -F '[sudo]'`

  {
    echo "machine  192.168.0.98"
    echo "login    kibana_system"
    echo "password $es_pass"
  } > netrc

  sed -i -e "s|^\(elasticsearch.password\): .*|\1: $es_pass|" \
    kibana.yml.template > kibana.yml

  rm -f kibana.log
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

