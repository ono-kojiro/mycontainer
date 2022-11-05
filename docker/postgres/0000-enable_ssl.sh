#!/bin/bash
set -e

cp -f /tmp/postgres+3-key.pem /var/lib/postgresql/data/
cp -f /tmp/postgres+3.pem     /var/lib/postgresql/data/

config="/var/lib/postgresql/data/postgresql.conf"

{
  echo "ssl = on"
  echo "ssl_cert_file = 'postgres+3.pem'"
  echo "ssl_key_file = 'postgres+3-key.pem'"
} >> $config

