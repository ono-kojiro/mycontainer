#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ret=0

ENVFILE=".env"

if [ -e "${ENVFILE}" ]; then
  . ./${ENVFILE}
fi

if [ "$ret" -ne 0 ]; then
  exit $ret
fi

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    create            create container
    start             start container
    stop              stop container
    down              remove container

    destroy           remove container and volume
EOF
}

help()
{
  usage
}

attach_nginx()
{
  docker exec -it nginx /bin/sh
}


attach_couchdb()
{
  docker exec -it couchdb /bin/bash
}

dump_config()
{
  docker exec -i couchdb /bin/bash -s << EOF
  {
    curl -s -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} \
      http://localhost:5984/_node/_local/_config
  }
EOF

}

dump()
{
  dump_config
}

log_nginx()
{
  docker compose logs -f nginx
}

log_couchdb()
{
  docker compose logs -f couchdb
}

create()
{
  docker compose --env-file ${ENVFILE} up --no-start

  enable_ssl  
  
  enable_couchdb
  enable_proxy_auth
}

enable_ssl()
{
  echo    "INFO: enable ssl"
  echo -n "INFO: create dummy container ... "
  docker container create --name dummy \
     -v "nginx-config:/etc/nginx" alpine >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
  
  echo -n "INFO: pre-process"
  docker run --rm -i -u root \
    -v "nginx-config:/etc/nginx" \
    -v "nginx-data:/usr/share/nginx/html" \
    alpine /bin/sh -s << EOF
  {
    mkdir -p /etc/nginx/certs
    mkdir -p /etc/nginx/includes
    rm -f    /etc/nginx/conf.d/default.conf
  }
EOF
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: upload configs ... "
  docker cp -q config/ssl/nginx.crt   dummy:/etc/nginx/certs/
  docker cp -q config/ssl/nginx.key   dummy:/etc/nginx/certs/
  docker cp -q config/ssl/location.conf   dummy:/etc/nginx/includes/
  docker cp -q config/ssl/ssl.conf   dummy:/etc/nginx/includes/
  docker cp -q config/ssl/ssl-server.conf   dummy:/etc/nginx/conf.d/
  docker cp -q config/nginx/default-location.conf dummy:/etc/nginx/includes/
  echo ""
  
  echo -n "INFO: remove dummy container ... "
  docker rm dummy >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
}

enable_couchdb()
{
  docker cp -q config/nginx/couchdb-common.conf   nginx:/etc/nginx/includes/
  docker cp -q config/nginx/couchdb-location.conf nginx:/etc/nginx/includes/

  #docker cp -q config/ssl/ssl_site.conf dummy:/etc/nginx/conf.d/ssl_site.conf
  docker cp -q config/nginx/couchdb-server.conf \
    nginx:/etc/nginx/conf.d/
  
  echo -n "INFO: post-process ... "
  docker run --rm -i -u root \
    -v "nginx-config:/etc/nginx" \
    -v "nginx-data:/usr/share/nginx/html" \
    alpine /bin/sh -s << EOF
  {
    rm -f /etc/nginx/conf.d/default.conf
  }
EOF
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  #echo -n "INFO: remove dummy container ... "
  #docker rm dummy >/dev/null
  #if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
}

enable_proxy_auth()
{
  echo "INFO: enable proxy authentication"
  echo -n "INFO: create dummy container ... "
  docker container create --name dummy \
     -v "couchdb-config:/opt/couchdb/etc/local.d" \
     alpine >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
  
  echo -n "INFO: upload config/couchdb/proxy.ini ... "
  docker cp -q config/couchdb/proxy.ini      dummy:/opt/couchdb/etc/local.d/
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
  
  echo -n "INFO: remove dummy container ... "
  docker rm dummy >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
}

start()
{
  docker compose --env-file ${ENVFILE} start
}

status()
{
  docker ps -a | grep -e couchdb -e nginx
}

stop()
{
  docker compose --env-file ${ENVFILE} stop
}

restart()
{
  stop
  start
}

down()
{
  echo -n "INFO: container down ... "
  docker compose --env-file ${ENVFILE} down >/dev/null 2>&1
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
}

destroy()
{
  down
  volumes="couchdb-config couchdb-data nginx-config nginx-data"
  for volume in $volumes; do
    echo "INFO: remove $volume"
    docker volume rm $volume >/dev/null 2>&1
  done
}

test()
{
  #test_http
  test_https
  test_nginx
  test_couchdb
}

test_nginx()
{
  curl https://localhost
}

test_http()
{
  curl -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} http://localhost
}

test_https()
{
  curl -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} https://localhost

}

test_couchdb()
{
  curl \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} https://localhost/couchdb/
}

all_dbs()
{
  curl -s -k \
    -u ${COUCHDB_USER}:${COUCHDB_PASSWORD} https://localhost/couchdb/_all_dbs
}

all()
{
  :
}

args=""

while [ "$#" -ne 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "$args" ]; then
  all
fi

for target in $args; do
  target=`echo $target | tr '-' '_'`
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done

