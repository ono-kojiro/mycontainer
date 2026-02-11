#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=./.env

if [ -e "${ENVFILE}" ]; then
  . ${ENVFILE}
fi

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    clone
    build

    fetch
    update
    patch

    create
    replace_crt
    copy_image

    dbcert

    start
    stop

    down
    destroy

    help
EOF
}

help()
{
  usage
}

all()
{
    clone
    build

    fetch
    update
    patch

    create
    replace_crt
    copy_image

    start
}

config()
{
    replace_crt
    copy_image

    dbcert
}

clone()
{
  if [ ! -e "snipe-it" ]; then
    git clone https://github.com/grokability/snipe-it.git
  else
    git -C snipe-it pull
  fi

  git -C snipe-it checkout -f v8.3.7
}

build()
{
  cd snipe-it
  docker build -t snipe-it:${APP_VERSION} .
  cd ${top_dir}
}

fetch()
{
  curl -O https://raw.githubusercontent.com/snipe/snipe-it/master/docker-compose.yml
  curl --output .env https://raw.githubusercontent.com/snipe/snipe-it/master/.env.docker

}

update()
{
  sed -ie "s/APP_VERSION=\(.*\)/APP_VERSION=v8.3.7-ubuntu/" .env
  sed -ie "s/APP_PORT=\(.*\)/APP_PORT=8443/" .env
  sed -ie "s|APP_URL=\(.*\)|APP_URL=https://192.168.1.72:8443|" .env
  sed -ie "s/APP_TIMEZONE='UTC'/APP_TIMEZONE='JST'/" .env
  sed -ie "s/APP_LOCALE=en-US/APP_LOCALE=ja-JP/" .env

  sed -ie "s/DB_PASSWORD=\(.*\)/DB_PASSWORD=mypasswd/" .env
  sed -ie "s/MYSQL_ROOT_PASSWORD=\(.*\)/MYSQL_ROOT_PASSWORD=mypasswd/" .env
}

patch()
{
  command patch -p0 -i 0000-change_name.patch
}


full()
{
  create
  start
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

attach_app()
{
  docker exec -it snipe-it-app /bin/bash
}

attach_db()
{
  docker exec -it snipe-it-db /bin/bash
}

replace_crt()
{
  docker cp snipe-it-app.crt snipe-it-app:/var/lib/snipeit/ssl/snipeit-ssl.crt
  docker cp snipe-it-app.key snipe-it-app:/var/lib/snipeit/ssl/snipeit-ssl.key
}

copy_image()
{
  docker cp snipe-it-app:/var/www/html/public/img/demo/avatars/default.png .
  docker cp default.png snipe-i-app:/var/www/html/public/uploads/
}

ca()
{
  docker cp myrootca.crt snipe-it-app:/usr/local/share/ca-certificates/
  docker exec -it snipe-it-app update-ca-certificates
}

dbcert()
{
  docker cp snipe-it-db.key snipe-it-db:${DB_SSL_KEY_PATH}
  docker cp snipe-it-db.crt snipe-it-db:${DB_SSL_CERT_PATH}
  docker cp myrootca.crt    snipe-it-db:${DB_SSL_CA_PATH}
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

