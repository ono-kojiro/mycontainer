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
  
builddir="./work/build/${pkgname}-${pkgver}"

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

    postproc
}

fetch()
{
  mkdir -p work/sources
  cd work/sources
  if [ ! -e "v${pkgver}.tar.gz" ]; then
    curl -O -L ${source_url}
  fi
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
  cd work/build/${pkgname}-${pkgver}
  docker build -t ${pkgname}:${pkgver}-ubuntu .
  cd ${top_dir}
}

config()
{
  cp -f ${builddir}/docker-compose.yml .
  cp -f ${builddir}/.env.docker .env

  update_app
  update_db

  patch
}

update_app()
{
  sed -i -e "s/APP_VERSION=\(.*\)/APP_VERSION=${pkgver}-ubuntu/" .env
  sed -i -e "s/APP_PORT=\(.*\)/APP_PORT=8443/" .env
  sed -i -e "s|APP_URL=\(.*\)|APP_URL=https://192.168.1.72:8443|" .env
  sed -i -e "s/APP_TIMEZONE='UTC'/APP_TIMEZONE='JST'/" .env
  sed -i -e "s/APP_LOCALE=en-US/APP_LOCALE=ja-JP/" .env

  sed -i -e "s/DB_PASSWORD=\(.*\)/DB_PASSWORD=mypasswd/" .env
  sed -i -e "s/MYSQL_ROOT_PASSWORD=\(.*\)/MYSQL_ROOT_PASSWORD=mypasswd/" .env
}

update_db()
{
  #sed -i -e "s|\(DB_SSL\)=\(.*\)|\1=true|" .env
  sed -i -e "s|\(DB_SSL_KEY_PATH\)=\(.*\)|\1=/etc/mysql/server-key.pem|" .env
  sed -i -e "s|\(DB_SSL_CERT_PATH\)=\(.*\)|\1=/etc/mysql/server-cert.pem|" .env
  sed -i -e "s|\(DB_SSL_CA_PATH\)=\(.*\)|\1=/etc/mysql/cacert.pem|" .env
}

patch()
{
  command patch -p0 -i 0000-change_name.patch
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
  upload_ca
}

replace_crt()
{
  docker cp snipe-it-app.crt snipe-it-app:/var/lib/snipeit/ssl/snipeit-ssl.crt
  docker cp snipe-it-app.key snipe-it-app:/var/lib/snipeit/ssl/snipeit-ssl.key
}

upload_ca()
{
  docker cp myrootca.crt snipe-it-app:/usr/local/share/ca-certificates/
}

postproc()
{
  copy_png
}

copy_png()
{
  docker exec -it snipe-it-app mkdir -p /var/www/html/public/uploads
  docker cp ${builddir}/public/uploads/default.png \
    snipe-it-app:/var/www/html/public/uploads/
}

##### common functions ##########
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

