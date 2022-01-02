#!/bin/sh

. ../config.bashrc

docker build --tag $mediawiki_image .
	
setup_mediawiki()
{
  docker run \
    -d \
    --net=mediawiki-nw \
	--name $mediawiki_name \
	-p 10080:80 \
	-p 10443:443 \
	-e MYSQL_USER=mediawiki \
	-e MYSQL_PASSWORD=mediawiki \
	-e MYSQL_DATABASE=mediawiki \
	-e MYSQL_RANDOM_ROOT_PASSWORD=yes \
	--link mariadb \
	$mediawiki_image
}

setup_mediawiki

