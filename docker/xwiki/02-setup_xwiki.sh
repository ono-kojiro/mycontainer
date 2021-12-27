#!/bin/sh

sudo mkdir -p /opt/xwiki-docker/xwiki

setup_xwiki()
{
  docker run \
    -d \
    --net=xwiki-nw \
	--name xwiki \
	-p 8090:8080 \
	-v /opt/xwiki-docker/xwiki:/usr/local/xwiki \
	-e DB_USER=xwiki \
	-e DB_PASSWORD=xwiki \
	-e DB_DATABASE=xwiki \
	-e DB_HOST=mariadb-xwiki \
	xwiki:lts-mysql-tomcat
}

setup_xwiki

