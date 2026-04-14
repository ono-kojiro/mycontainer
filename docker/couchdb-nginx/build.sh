#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

flags=""

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

    upload            upload certificates

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
}

attach()
{
  docker exec -it couchdb /bin/bash
}

init()
{
  curl -X POST http://admin:secret@localhost:5984/_cluster_setup \
    -H "Content-Type: application/json" \
    -d '{"action": "finish_cluster"}'
}

check()
{
  cmd="curl -k -X GET https://admin:secret@localhost:6984/"
  echo "DEBUG: $cmd"
  $cmd
}

enable_ssl()
{
  SHELL_FORMAT=`cat .env | sed -e 's/#.*//' | grep -v -e '^$' | awk '{printf "env %s ", $0}'`
  ${SHELL_FORMAT} envsubst \
          < config/couchdb/ssl.ini.template \
          > config/couchdb/ssl.ini
  
  docker cp config/couchdb/couchdb.crt couchdb:/tmp/
  docker cp config/couchdb/couchdb.key couchdb:/tmp/
  docker cp config/couchdb/ssl.ini couchdb:/opt/couchdb/etc/local.d/
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

ssl()
{
  enable_ssl
}

log()
{
  docker compose logs -f couchdb
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

hosts()
{
  ansible-inventory -i inventory.yml --list --yaml > hosts.yml
}

deploy()
{
  ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t $tag site.yml
}

hosts

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
    -* )
      flags="$flags $1"
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "$args" ]; then
  help
fi

for target in $args; do
  num=`LANG=C type "$target" 2>&1 | grep 'function' | wc -l`
  if [ "$num" -eq 1 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done

