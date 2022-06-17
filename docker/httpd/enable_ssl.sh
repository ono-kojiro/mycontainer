#!/usr/bin/env sh

sudo docker cp /etc/ssl/server/server.crt httpd:/usr/local/apache2/conf/
sudo docker cp /etc/ssl/server/server.key httpd:/usr/local/apache2/conf/

cat - << 'EOS' | docker exec -i httpd /bin/bash
sed -i \
        -e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
        -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        /usr/local/apache2/conf/httpd.conf
EOS

# docker-compose stop
# docker-compose start

