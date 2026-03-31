#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=./.env

pkgname="couchdb"
pkgver="3.5.1"

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    fetch             fetch source archive
    extract           extract source code
    
    config            copy docker-compose.yml and configure
    build             build docker image
    
    create            create container
    upload            upload certificates

    start             start container
    postproc
EOF
}

help()
{
  usage
}

all()
{
    create
    upload

    start
    postproc
}

certs()
{
  docker cp couchdb.crt couchdb:/opt/couchdb/etc/
  docker cp couchdb.key couchdb:/opt/couchdb/etc/
}

upload_ca()
{
  docker cp myrootca.crt snipe-it-app:/usr/local/share/ca-certificates/
}

attach()
{
  docker exec -it couchdb /bin/bash
}

init()
{
  curl -X POST http://admin:secret@192.168.1.52:5984/_cluster_setup \
    -H "Content-Type: application/json" \
    -d '{"action": "finish_cluster"}'
}

check()
{
  curl -X GET http://admin:secret@192.168.1.52:5984/_all_dbs/
}

ssl()
{
  docker cp couchdb.crt couchdb:/tmp/
  docker cp couchdb.key couchdb:/tmp/
  docker cp custom.ini  couchdb:/tmp/
  docker exec -i couchdb /bin/bash << EOF
{
  mkdir -p /opt/couchdb/etc/certs
  mv -f /tmp/couchdb.* /opt/couchdb/etc/certs/
  chown couchdb:couchdb /opt/couchdb/etc/certs/couchdb.*
  chmod 600 /opt/couchdb/etc/certs/couchdb.key

  mv -f /tmp/custom.ini /opt/couchdb/etc/local.d/
}
EOF

}

eldap()
{
  docker exec -i couchdb /bin/bash << EOF
{
  apt-get -y update
  apt-get -y install erlang-eldap
  ln -s -f /usr/lib/erlang/lib/eldap-1.2.10 /opt/couchdb/lib/
}
EOF

}

ldap()
{
  docker cp ebin.tar.gz couchdb:/tmp/
  docker exec -i couchdb /bin/bash << EOF
{
  mkdir -p /opt/couchdb/lib/ldap_auth-2.0.0
  cd /opt/couchdb/lib/ldap_auth-2.0.0
  tar xzvf /tmp/ebin.tar.gz
}
EOF

}

config()
{
  #defaultconfig
  localconfig
}

defaultconfig()
{
  docker cp default.d-ldap_auth.ini couchdb:/opt/couchdb/etc/default.d/ldap_auth.ini

}

localconfig()
{
  #docker cp local.d-ldap_auth.ini couchdb:/opt/couchdb/etc/local.d/ldap_auth.ini
  docker cp ldap_auth.ini couchdb:/opt/couchdb/etc/local.d/ldap_auth.ini
}

unconfig()
{
  docker exec -i couchdb /bin/bash << EOF
{
  rm -f /opt/couchdb/etc/default.d/ldap_auth.ini
  rm -f /opt/couchdb/etc/local.d/ldap_auth.ini
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
  docker volume rm snipe-it_db_data
  docker volume rm snipe-it_storage
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

