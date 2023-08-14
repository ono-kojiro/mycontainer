#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name=elasticsearch
     
username="elastic"
#password="*fcGVoJfc6ZYTHnxZD*Y"
password="N1HSk2rOkdHFF2NwZ29C"

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

build()
{
  docker build -t elasticsearch .
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
  docker ps -f name=$name
}

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

reset()
{
  ansible-playbook -K -i hosts.yml reset.yml
}

chpasswd()
{
   echo "Setting kibana_system password";
   curl \
     -X POST --cacert mylocalca.pem \
     -u "elastic:elastic" \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/_security/user/kibana_system/_password \
     -d "{ \"password\":\"elastic\" }"
}

restart()
{
  stop
  start
}

test()
{
  test_http
}

test_http()
{
   echo "test http"
   curl -s \
     -u "elastic:*fcGVoJfc6ZYTHnxZD*Y" \
     -H "Content-Type: application/json" \
     http://192.168.0.98:9200/

   #w3m -dump http://192.168.0.98:5601/
}

test_https()
{
   echo "test https"
   curl -k \
     -u "$username:$password" \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/
   
  #w3m -dump http://192.168.0.98:5601/
}

test_simple()
{
   curl \
     -X GET --cacert mylocalca.pem \
     -u "kibana_system:elastic" \
     -H "Content-Type: application/json" \
     https://192.168.0.98:9200/ 
}

create_user()
{
  es_host="192.168.0.98:9200"

  username=$USER
  fullname=`git config --get user.name`
  email=`git config --get user.mail`

  stty -echo
  printf "Password: "
  read PASSWORD
  stty echo
  printf "\n"

  password=$PASSWORD

  curl -k --netrc-file ./.netrc \
    -H 'Content-Type: application/json' \
    -XPOST "https://$es_host/_security/user/$username?pretty" --data @- << EOS
{
  "password" : "$password",
  "enabled" : true,
  "roles" : [ "superuser", "kibana_admin" ],
  "full_name" : "$fullname",
  "email" : "$email",
  "metadata" : {
    "intelligence" : 7
  }
}
EOS

}

debug()
{
  docker cp kibana:/usr/share/kibana/logs/kibana.log .
}

es()
{
  docker exec -it --user root elasticsearch /bin/bash
}

kibana()
{
  docker exec -it --user root kibana /bin/bash
}

logstash()
{
  docker exec -it --user root logstash /bin/bash
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

