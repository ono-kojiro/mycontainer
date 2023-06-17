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

    chpasswd
    
    restart
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
  cat - << 'EOF' | sudo bash -s
    rm -rf /var/lib/elasticsearch
    mkdir -p /var/lib/elasticsearch
    mkdir -p /var/lib/elasticsearch/certs
    mkdir -p /var/lib/elasticsearch/data
    mkdir -p /var/lib/elasticsearch/etc
  
    cp -f elasticsearch.yml /var/lib/elasticsearch/
    cp -f elasticsearch.crt /var/lib/elasticsearch/certs/
    cp -f elasticsearch.key /var/lib/elasticsearch/certs/
    cp -f mylocalca.pem     /var/lib/elasticsearch/certs/
    
    chown -R 1000:1000 /var/lib/elasticsearch
  
    mkdir -p /var/lib/kibana
    mkdir -p /var/lib/kibana/config/certs
    mkdir -p /var/lib/kibana/data
    cp    -f mylocalca.pem     /var/lib/kibana/config/certs/
    cp    -f kibana.crt        /var/lib/kibana/config/certs/
    cp    -f kibana.key        /var/lib/kibana/config/certs/
    cp    -f kibana.yml        /var/lib/kibana/config/
    chown -R 1000:1000 /var/lib/kibana
EOF
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

test_access()
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

