#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

. ./env

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."

  target:
    help

    create

    enable_ssl
    fetch
    patch
    upload

    start
    stop


    debug
    ps
    down
EOF
}

help()
{
  usage
}

full()
{
  create
  enable_ssl
  fetch
  patch
  upload
  start
}

create()
{
  docker compose --env-file ./env up --no-start
}

start()
{
  docker compose --env-file ./env start
}

stop()
{
  docker compose --env-file ./env stop
}

restart()
{
  stop
  start
}

down()
{
  docker compose --env-file ./env down
}

attach()
{
  docker exec -it ${CONTAINER_NAME} /bin/bash
}

attach_db()
{
  docker exec -it -u root redmine-db /bin/bash
  #docker exec -it -u nobody redmine-db /bin/bash
}


enable_ssl()
{
  files="redmine.crt redmine.key"
  for file in $files; do
    docker cp $file ${CONTAINER_NAME}:/usr/src/redmine/config/
  done
}

fetch()
{
  files=""
  files="$files config/environment.rb"
  files="$files config.ru"

  for file in $files; do
    echo "fetch $file ..."
    docker cp ${CONTAINER_NAME}:/usr/src/redmine/$file .
  done
}

patch()
{
  command patch -p1 -i 0000-change_prefix.patch
}

upload()
{
  # config.ru, environment.rb

  files=""
  files="$files environment.rb"
  
  for file in $files; do
    docker cp $file ${CONTAINER_NAME}:/usr/src/redmine/config/
  done
  
  filename="config.ru"
  if [ -e "$filename" ]; then  
    docker cp $filename ${CONTAINER_NAME}:/usr/src/redmine/
  fi
}

config()
{
  upload
}

ps()
{
  docker ps -a --no-trunc
}

all()
{
  usage
}

scrum()
{
  docker cp scrum-v0.23.0.tar.gz ${CONTAINER_NAME}:/tmp/
  docker compose --env-file env exec -T redmine bash -s << EOF
  {
    cd /usr/src/redmine/plugins/
    tar xzvf /tmp/scrum-v0.23.0.tar.gz
    cd /usr/src/redmine
    bundle exec rake redmine:plugins:migrate
  }
EOF
}

backup()
{
  docker compose --env-file env exec -T redmine-5.0.5 bash -s << EOF
  {
    cd /usr/src/redmine
    tar cjvf /tmp/files.tar.bz2 ./files
  }
EOF

  mkdir -p backup
  docker cp redmine-5.0.5:/tmp/files.tar.bz2 backup/

  docker compose --env-file env exec -T postgres-15.2 bash -s << EOF
  {
    su - postgres -c 'pg_dump -Fc postgres > /tmp/postgres.dump'
    su - postgres -c 'pg_dump -Fc template1> /tmp/template1.dump'
  }
EOF

  docker cp postgres-15.2:/tmp/postgres.dump  backup/
  docker cp postgres-15.2:/tmp/template1.dump backup/
}

restore()
{
  docker cp backup/files.tar.bz2 redmine:/tmp/
  docker cp backup/postgres.dump redmine-db:/tmp/
  docker cp backup/template1.dump redmine-db:/tmp/

  docker compose --env-file env exec -T redmine bash -s << EOF
  {
    cd /usr/src/redmine
    tar xjvf /tmp/files.tar.bz2
  }
EOF
  
  docker compose --env-file env exec -T db bash -s << EOF
  {
    su - postgres -c 'pg_restore -d postgres --clean --if-exists --no-owner /tmp/postgres.dump'
    #su - postgres -c 'psql -d postgres -f /tmp/postgres.dump'
    su - postgres -c 'pg_restore -d template1 --clean --if-exists --no-owner /tmp/template1.dump'
    #su - postgres -c 'psql -d template1 -f /tmp/template1.dump'
  }
EOF
}

while [ $# -ne 0 ]; do
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

if [ $# -eq 0 ]; then
  all
fi

for target in "$@"; do
  LANG=C type "$target" | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done

