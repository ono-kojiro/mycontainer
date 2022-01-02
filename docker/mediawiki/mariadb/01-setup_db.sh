#!/bin/sh

. ../config.bashrc

top_dir=`pwd`

mkdir -p $top_dir/mariadb
mkdir -p $top_dir/mariadb-init

setup_db()
{
  docker run \
  --net=mediawiki-nw \
  --name $mariadb_name \
  -v $top_dir/mariadb:/var/lib/mysql \
  -v $top_dir/mariadb-init:/docker-entrypoint-initdb.d \
  -e MYSQL_ROOT_PASSWORD=mediawiki \
  -e MYSQL_USER=mediawiki \
  -e MYSQL_PASSWORD=mediawiki \
  -e MYSQL_DATABASE=mediawiki \
  -d $mariadb_image \
  --character-set-server=utf8 \
  --collation-server=utf8_bin \
  --explicit-defaults-for-timestamp=1
}

setup_db

