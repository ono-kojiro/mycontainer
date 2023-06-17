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

enable_https()
{
  echo "enable https"
  config="/usr/share/elasticsearch/config"
  user="elasticsearch"
  name="elasticsearch"

  docker exec --user root $name mkdir -p $config/certs/
  docker cp elasticsearch.yml $name:$config/
  docker cp mylocalca.pem $name:$config/certs/
  docker cp elasticsearch.key $name:$config/certs/
  docker cp elasticsearch.crt $name:$config/certs/

  docker exec --user root $name chown $name:root $config/elasticsearch.yml
  docker exec --user root $name chown -R $name:root $config/certs/
  
}

push()
{
  echo "change elasticsearch config"
  config="/usr/share/elasticsearch/config"
  user="elasticsearch"

  docker cp elasticsearch.yml elasticsearch:$config/
  docker exec --user root elasticsearch \
    chown root.root $config/elasticsearch.yml
  docker exec --user elasticsearch elasticsearch mkdir -p $config/certs/
  docker cp mylocalca.pem elasticsearch:$config/certs/
  docker cp elasticsearch.key elasticsearch:$config/certs/
  docker cp elasticsearch.crt elasticsearch:$config/certs/
  docker exec --user root elasticsearch chown -R elasticsearch:elasticsearch $config/certs/
}

push_kibana()
{
  echo "change kibana config"
  docker cp kibana.yml kibana:/usr/share/kibana/config/kibana.yml
  docker exec --user kibana kibana mkdir -p /usr/share/kibana/config/certs/
  docker exec --user root kibana chown -R 1000:1000 /usr/share/kibana/config/certs/
  docker cp mylocalca.pem     kibana:/usr/share/kibana/config/certs/
}

test()
{
  test_http
}

test_http()
{
   echo "test http"
   curl -s \
     -u "elastic:elastic" \
     -H "Content-Type: application/json" \
     http://192.168.0.98:9200/

   #w3m -dump http://192.168.0.98:5601/
}

test_https()
{
   echo "test https"
   curl \
     -u "elastic:elastic" \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/
   
  #w3m -dump http://192.168.0.98:5601/
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

attach()
{
  docker exec -it --user root elasticsearch /bin/bash
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

