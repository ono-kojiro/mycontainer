#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

if [ -f ".env" ]; then
  . ./.env
fi
  
set -a
. ./.env
envsubst < filebeat.yml.template > filebeat.yml
set +a

help()
{
  usage
}

usage()
{
  cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    create
    start
    down
    destroy
EOS
}

all()
{
  help
}

prepare()
{
  beats_base
  beats_base="https://raw.githubusercontent.com/elastic/beats"
  curl -L -O ${beats_base}/9.3/deploy/docker/filebeat.docker.yml
}

fetch()
{
  debfile="filebeat-${FB_VER}-${FB_ARCH}.deb"
  wget \
    https://artifacts.elastic.co/downloads/beats/filebeat/${debfile}
}

build()
{
  docker build --tag filebeat .
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
}

ssh()
{
  command ssh localhost -p ${SSH_PORT}
}

attach()
{
  docker exec -it -u root ${CONTAINER_NAME} /bin/bash
}

config()
{
  docker cp filebeat.yml \
    ${CONTAINER_NAME}:/usr/share/filebeat/filebeat.yml

  docker cp ${CLIENT_CRT}  ${CONTAINER_NAME}:/usr/share/filebeat/
  docker cp ${CLIENT_KEY}  ${CONTAINER_NAME}:/usr/share/filebeat/
  docker cp ${CACERT}      ${CONTAINER_NAME}:/usr/share/filebeat/

  docker container create --name dummy \
    -v "filebeat-config:/usr/share/filebeat" alpine

  docker run --rm -i -u root \
    -v "filebeat-config:/usr/share/filebeat" alpine /bin/sh -s << EOF
  {
     chown root:root /usr/share/filebeat/filebeat.yml
     chown root:root /usr/share/filebeat/${CLIENT_CRT}
     chown 1000:1000 /usr/share/filebeat/${CLIENT_KEY}
  }
EOF

  docker rm dummy
}


log()
{
  docker logs ${CONTAINER_NAME}
}

status()
{
  docker ps -f name=$name
}

restart()
{
  stop
  start
}

test()
{
  test_http
}

stop()
{
  docker compose stop
}

down()
{
  docker compose down
}

destroy()
{
  down
  docker volume rm filebeat-config
  docker volume rm filebeat-data
}


deploy()
{
  ansible-playbook -K -i hosts.yml --extra-vars "$extra_vars" site.yml
}



if [ $# -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    -h )
      usage
	  ;;
    -v )
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
  if [ $? -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

