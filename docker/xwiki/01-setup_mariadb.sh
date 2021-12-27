#!/bin/sh

sudo mkdir -p /opt/xwiki-docker/mariadb
sudo mkdir -p /opt/xwiki-docker/mariadb-init

cat - << 'EOS' > /opt/xwiki-docker/mariadb-init
grant all privileges on *.* to xwiki@'%'
EOS

setup_mariadb()
{
  docker run \
  --net=xwiki-nw \
  --name mariadb-xwiki \
  -v /opt/xwiki-docker/mariadb:/var/lib/mysql \
  -v /opt/xwiki-docker/mariadb-init:/docker-entrypoint-initdb.d \
  -e MYSQL_ROOT_PASSWORD=xwiki \
  -e MYSQL_USER=xwiki \
  -e MYSQL_PASSWORD=xwiki \
  -e MYSQL_DATABASE=xwiki \
  -d mariadb:10.3 \
  --character-set-server=utf8 \
  --collation-server=utf8_bin \
  --explicit-defaults-for-timestamp=1
}

setup_mariadb

