#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."

  target:
    help

    up
    down
EOF
}

create()
{
  docker-compose up --no-start
}

up()
{
  docker-compose up
}

start()
{
  docker-compose start
}

stop()
{
  docker-compose stop
}

restart()
{
  stop
  start
}

down()
{
  docker-compose down
}

attach()
{
  docker exec -it redmine /bin/bash
}

upload()
{
  docker cp \
    redmine.crt \
    redmine:/usr/src/redmine/config/redmine.crt

  docker cp \
    redmine.key \
    redmine:/usr/src/redmine/config/redmine.key

  docker cp \
    puma.rb \
    redmine:/usr/src/redmine/config/puma.rb
  
  docker cp \
    development.rb \
    redmine:/usr/src/redmine/config/environments/development.rb

  docker cp \
    production.rb \
    redmine:/usr/src/redmine/config/environments/production.rb
}

ps()
{
  docker ps -a --no-trunc
}

debug()
{
  #docker cp redmine:/usr/local/bundle/gems/puma-6.1.1/lib/puma.rb .
  #docker cp \
  #  redmine:/usr/local/bundle/gems/puma-6.1.1/lib/rack/handler/puma.rb \
  #  handler-puma.rb

  #docker cp \
  #  redmine:/usr/src/redmine/config/environments/development.rb .
  #docker cp \
  #  redmine:/usr/src/redmine/config/environments/production.rb .
  #docker cp \
  #  redmine:/usr/src/redmine/config/environments/test.rb .
  
  docker cp \
    redmine:/docker-entrypoint.sh .
}

all()
{
  usage
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

