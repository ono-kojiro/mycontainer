#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

. ./env

extra_vars=`cat env | tr '\n' ' '`

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
  wget https://artifacts.elastic.co/downloads/logstash/logstash-$LS_VER-$LS_ARCH.deb
}

deploy()
{
  ansible-playbook -K -i hosts.yml --extra-vars "$extra_vars" site.yml
}

update()
{
  ansible-playbook -K -i hosts.yml --extra-vars "$extra_vars" update.yml
}

reset()
{
  ssh -t elk \
    sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password \
        -u logstash_system --silent --batch | tee password.log
  
  sed -i -e 's|||' password.log
  pass=`cat password.log | grep -v -F '[sudo]'`

  {
    echo "machine  192.168.0.98"
    echo "login    logstash_system"
    echo "password $pass"
  } > netrc
  
  sed -i -e "s|\(\s*\)password => .*|\1password => \"$pass\"|" example.conf
  rm -f password.log
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
  test_http
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

