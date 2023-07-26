#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

image="postgres"
tag="15.3-alpine3.18"
container="$image"

docker_compose="docker compose"

help()
{
    usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    build/create
    start
    
    db/user
    test_admin

    enable_ldap
    test_ldap

    stop
    destroy
EOS

}

all()
{
  create
  start
  
  sleep 2
  db
  user
  
  enable_ldap
  enable_tls

  $docker_compose stop
  $docker_compose start

  #test_admin
}

build()
{
  docker build --tag $image:$tag --no-cache .
}

create()
{
  $docker_compose up --no-start
}

start()
{
  $docker_compose start
}

status()
{
  docker ps -a
}

attach()
{
  docker exec -it $container /bin/bash
}

initdb()
{
  docker exec -i $container /bin/bash << EOS

ps -ef
psql -h localhost -u
EOS
  
}

connect()
{
  PGSSLROOTCERT=$HOME/.local/share/mkcert/rootCA.pem psql \
    -h localhost -p 15432 sampledb $USER
}

db()
{
  docker exec -i postgres /bin/bash << EOS

createdb -U postgres sampledb

EOS

}

user()
{
  docker exec -i postgres /bin/bash << EOS

createuser -U postgres -d $USER

EOS

}

enable_ldap()
{
  docker exec -i postgres /bin/bash << 'EOS'

  grep 'ldapserver=' /var/lib/postgresql/data/pg_hba.conf
  if [ $? -ne 0 ]; then
  {
    echo 'local   all   all                    ldap ldapserver=192.168.0.98  ldapprefix="uid=" ldapsuffix=",ou=Users,dc=example,dc=com"' 
    echo 'host all all all ldap ldapserver=192.168.0.98  ldapprefix="uid=" ldapsuffix=",ou=Users,dc=example,dc=com"'
  } >> /var/lib/postgresql/data/pg_hba.conf
  fi

EOS

}

test_admin()
{
  docker exec -it postgres psql -U postgres
}

test_ldap()
{
   #PGSSLROOTCERT=$HOME/.local/share/mkcert/rootCA.pem \
    psql sampledb -h localhost -p 15432 -U $USER
}

enable_tls()
{
  crtfile="postgres.crt"
  keyfile="postgres.key"

  docker cp $crtfile postgres:/var/lib/postgresql/data/
  docker cp $keyfile     postgres:/var/lib/postgresql/data/

  docker exec -i postgres /bin/bash << EOS

chown postgres:postgres /var/lib/postgresql/data/postgres.crt
chown postgres:postgres /var/lib/postgresql/data/postgres.key

config="/var/lib/postgresql/data/postgresql.conf"

grep 'ssl = on' $config

if [ $? -ne 0 ]; then
{
  echo "ssl = on"
  echo "ssl_cert_file = '$crtfile'"
  echo "ssl_key_file = '$keyfile'"
} >> $config

fi

EOS

}

stop()
{
  $docker_compose stop
}

destroy()
{
  $docker_compose down
}

clean()
{
  destroy
}


if [ "$#" = "0" ]; then
  usage
  exit 1
fi

args=""

while [ "$#" != "0" ]; do
  case "$1" in
    h)
      usage
	  ;;
    v)
      verbose=1
	  ;;
    *)
	  args="$args $1"
	  ;;
  esac

  shift

done

for target in $args ; do
  LANG=C type $target | grep function > /dev/null 2>&1
  if [ "$?" = "0" ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

