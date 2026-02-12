#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ENVFILE=./.env

pkgname="snipe-it"
pkgver="8.3.7"

if [ -e "${ENVFILE}" ]; then
  . ${ENVFILE}
fi

if [ -z "${APP_VERSION}" ]; then
  APP_VERSION="$pkgver"
fi
    
site="https://github.com/grokability/${pkgname}"
source_url="$site/archive/refs/tags/v${pkgver}.tar.gz"

usage()
{
  cat - << EOF
usage : $0 [options] target1 target2 ..."
  target:
    clone         clone snipe-it repository
    build         build snipe-it ubuntu image

    fetch
    update
    patch

    create
    replace_crt
    copy_png

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
    #fetch
    #extract
    #build

    config

    create
    upload

    start
    post
}

fetch()
{
  mkdir -p work/sources
  cd work/sources
  if [ ! -e "v${pkgver}.tar.gz" ]; then
    curl -O -L ${source_url}
  fi

  #echo "INFO: download docker-compose.yml"
  #curl -O https://raw.githubusercontent.com/snipe/snipe-it/master/docker-compose.yml
  #echo "INFO: download .env"
  #curl --output .env https://raw.githubusercontent.com/snipe/snipe-it/master/.env.docker

  cd ${top_dir}
}

extract()
{
  archive=`basename ${source_url}`
  mkdir -p work/build
  cd work/build
  tar -xzvf ../sources/${archive}
  cd ${top_dir}
}

build()
{
  cd work/build/snipe-it-${pkgver}
  docker build -t snipe-it:${pkgver}-ubuntu .
  cd ${top_dir}
}

config()
{
  cp -f work/build/${pkgname}-${pkgver}/docker-compose.yml .
  cp -f work/build/${pkgname}-${pkgver}/.env.docker .env

  update_app
  update_db

  patch
  #replace_crt
  #copy_image

  #dbcert
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


update_app()
{
  sed -ie "s/APP_VERSION=\(.*\)/APP_VERSION=${pkgver}-ubuntu/" .env
  sed -ie "s/APP_PORT=\(.*\)/APP_PORT=8443/" .env
  sed -ie "s|APP_URL=\(.*\)|APP_URL=https://192.168.1.72:8443|" .env
  sed -ie "s/APP_TIMEZONE='UTC'/APP_TIMEZONE='JST'/" .env
  sed -ie "s/APP_LOCALE=en-US/APP_LOCALE=ja-JP/" .env

  sed -ie "s/DB_PASSWORD=\(.*\)/DB_PASSWORD=mypasswd/" .env
  sed -ie "s/MYSQL_ROOT_PASSWORD=\(.*\)/MYSQL_ROOT_PASSWORD=mypasswd/" .env
}

update_db()
{
  :
  #sed -ie "s|\(DB_SSL\)=\(.*\)|\1=true|" .env
  sed -ie "s|\(DB_SSL_KEY_PATH\)=\(.*\)|\1=/etc/mysql/server-key.pem|" .env
  sed -ie "s|\(DB_SSL_CERT_PATH\)=\(.*\)|\1=/etc/mysql/server-cert.pem|" .env
  sed -ie "s|\(DB_SSL_CA_PATH\)=\(.*\)|\1=/etc/mysql/cacert.pem|" .env
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

upload()
{
  echo "INFO: replace cert"
  replace_crt
  echo "INFO: copy ca"
  ca
}

replace_crt()
{
  docker cp snipe-it-app.crt snipe-it-app:/var/lib/snipeit/ssl/snipeit-ssl.crt
  docker cp snipe-it-app.key snipe-it-app:/var/lib/snipeit/ssl/snipeit-ssl.key
}

copy_png()
{
  docker exec -it snipe-it-app mkdir -p /var/www/html/public/uploads
  docker cp ./work/build/snipe-it-8.3.7/public/uploads/default.png \
    snipe-it-app:/var/www/html/public/uploads/
}

post()
{
  copy_png
}

ca()
{
  docker cp myrootca.crt snipe-it-app:/usr/local/share/ca-certificates/
  #docker exec -it snipe-it-app update-ca-certificates
}

postproc()
{
  dbcert
  change_owner
}

dbcert()
{
  docker cp snipe-it-db.key snipe-it-db:${DB_SSL_KEY_PATH}
  docker cp snipe-it-db.crt snipe-it-db:${DB_SSL_CERT_PATH}
  docker cp myrootca.crt    snipe-it-db:${DB_SSL_CA_PATH}

}

change_owner()
{
  docker exec -it snipe-it-db chown mysql:mysql ${DB_SSL_KEY_PATH}
  docker exec -it snipe-it-db chown root:root ${DB_SSL_CERT_PATH}
  docker exec -it snipe-it-db chown root:root ${DB_SSL_CA_PATH}
}

enable_ssl()
{
  :
  server_cnf="/etc/mysql/mariadb.conf.d/50-server.cnf"
  docker exec -it snipe-it-db \
    sed -i -e 's|^#\(ssl-ca = .\+\)|\1|' $server_cnf
  docker exec -it snipe-it-db \
    sed -i -e 's|^#\(ssl-cert = .\+\)|\1|' $server_cnf
  docker exec -it snipe-it-db \
    sed -i -e 's|^#\(ssl-key = .\+\)|\1|' $server_cnf
  docker exec -it snipe-it-db \
    sed -i -e 's|^#bind-address.\+=.\+|bind-address = 0.0.0.0|' $server_cnf
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

