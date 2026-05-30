#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ret=0

ENVFILE=".env"

set -a
. ./.env
envsubst < traefik-dynamic.yml.template > traefik-dynamic.yml
envsubst < traefik.yml.template         > traefik.yml
set +a


if [ -e "${ENVFILE}" ]; then
  . ./${ENVFILE}
fi

if [ -z "${TRAEFIK_VERSION}" ]; then
  echo "ERROR: TRAEFIK_VERSION is not defined"
  ret=`expr $ret + 1`
fi

if [ -z "${TRAEFIK_IP}" ]; then
  echo "ERROR: TRAEFIK_IP is not defined"
  ret=`expr $ret + 1`
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

attach()
{
  docker exec -it traefik /bin/sh
}

dump_config()
{
  curl -s -k \
    -u ${couchdb_user}:${couchdb_password} https://${COUCHDB_HTTPS}/_node/_local/_config \
  | jq .
}

dump()
{
  dump_config
}

log()
{
  docker compose logs -f ${hostname}
}

create_net()
{
   docker network ls | tail -n +2 | awk '{ print $2 }' \
     | grep traefik-net >/dev/null 2>&1

   if [ "$?" -eq 0 ]; then
     echo "skip creating traefik-net"
   else
     docker network create \
       --subnet=172.31.0.0/24 \
       traefik-net
   fi
}

create()
{
  create_net
  docker compose up --no-start

  config
}

config()
{
  echo -n "INFO: create dummy container ... "
  docker container create --name dummy \
     -v "traefik-config:/etc/traefik" \
     alpine >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: upload traefik.yml ... "
  docker cp -q traefik.yml dummy:/etc/traefik/
  docker cp -q traefik-dynamic.yml dummy:/etc/traefik/
  docker cp -q mylocalca.crt dummy:/etc/traefik/
  docker cp -q traefik.crt dummy:/etc/traefik/
  docker cp -q traefik.key dummy:/etc/traefik/
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
  
  echo -n "INFO: change permission ... "
  docker run --rm -i -u root \
    -v "traefik-config:/etc/traefik" \
    alpine /bin/sh -s << EOF
  {
    chown -R 1001:1001 /etc/traefik/traefik.yml
  }
EOF
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: remove dummy container ... "
  docker rm dummy >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi
}

check()
{
  echo -n "INFO: create dummy container ... "
  docker container create --name dummy \
     -v "traefik-config:/etc/traefik" \
     alpine >/dev/null
  if [ "$?" -eq 0 ]; then echo "passed"; else echo "failed"; fi

  echo -n "INFO: check permission ... "
  docker run --rm -i -u root \
    -v "traefik-config:/etc/traefik" \
    alpine /bin/sh -s << EOF
  {
    ls -l /etc/traefik/traefik.yml
  }
EOF
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
  docker ps -a | grep traefik
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
  docker volume rm traefik-config
  docker network rm traefik-net
}

test_https()
{
  curl https://localhost:6984/
}

all()
{
  help
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

