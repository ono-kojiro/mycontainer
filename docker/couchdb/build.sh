#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=".env"

pkgname="couchdb"
pkgver="3.5.1"

if [ -e "${ENVFILE}" ]; then
  . ./${ENVFILE}
fi

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    create            create container
    start             start container
    
    ssl               enable ssl
    stop              stop container
    down              remove container
    destroy           remove container and volume

EOF
}

help()
{
  usage
}

all()
{
    create
    start
    postproc
}

attach()
{
  docker exec -it couchdb /bin/bash
}

check()
{
  cmd="curl -k -X GET https://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:6984/"
  #echo "DEBUG: $cmd"
  $cmd
}

ssl()
{
  docker cp config/ssl/couchdb.crt couchdb:/tmp/
  docker cp config/ssl/couchdb.key couchdb:/tmp/
  docker cp config/ssl/ssl.ini couchdb:/opt/couchdb/etc/local.d/
  docker exec -i couchdb /bin/bash << EOF
{
  mkdir -p /opt/couchdb/etc/certs
  mv -f /tmp/couchdb.* /opt/couchdb/etc/certs/
  chown couchdb:couchdb /opt/couchdb/etc/certs/couchdb.*
  chmod 600 /opt/couchdb/etc/certs/couchdb.key
  chmod 644 /opt/couchdb/etc/local.d/ssl.ini
}
EOF

}

config()
{
  defaultconfig
  localconfig
}

defaultconfig()
{
  :
}

localconfig()
{
  docker cp local.ini couchdb:/opt/couchdb/etc/local.d/
}

unconfig()
{
  docker exec -i couchdb /bin/bash << EOF
{
  rm -f /opt/couchdb/etc/local.d/local.ini
}
EOF
}


log()
{
  docker compose logs -f couchdb
}

mod()
{
  docker cp couchdb:/opt/couchdb/etc/local.d/docker.ini .
}

postproc()
{
  copy_png
}

create()
{
  docker compose --env-file ${ENVFILE} up --no-start
}

start()
{
  docker compose --env-file ${ENVFILE} start
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
  docker compose --env-file ${ENVFILE} down
}

destroy()
{
  down
  docker volume rm couchdb-data
}


ps()
{
  docker ps -a --no-trunc
}

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
      break
      ;;
  esac

  shift
done

if [ "$#" -eq 0 ]; then
  all
fi

for target in "$@"; do
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done

