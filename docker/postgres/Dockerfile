FROM postgres:14.5-alpine3.16

#USER postgres
#
# mkcert postgres 192.168.0.98 127.0.0.1 localhost
#

COPY postgres+3.pem     /tmp/
COPY postgres+3-key.pem /tmp/
COPY 0000-enable_ssl.sh    /docker-entrypoint-initdb.d/

RUN  chown postgres:postgres /tmp/postgres+3-key.pem

#CMD ["docker-entrypoint.sh", "postgres"]

