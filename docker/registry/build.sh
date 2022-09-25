#!/bin/sh

# https://stackoverflow.com/questions/25436742/how-to-delete-images-from-a-private-docker-registry

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

regserver="192.168.0.98:5000"

help()
{
  cat - << EOS
usage : $0 [OPTIONS] [TARGET] [TARGET...]
  options
    -h, --help            show this message
    -c, --codename        ex. jammy
    -i, --image           ex. jammy-ja
    -t, --tag             ex. 0.0.1

  target:
    clean
EOS

}

list()
{
  curl http://$regserver/v2/simple/tags/list
}

manifest()
{
  curl http://$regserver/v2/simple/manifests/latest \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    > manifest.json 2> /dev/null
}

delete()
{
  digest=$(cat manifest.json | jq -r '.config.digest')
  curl -v -X DELETE http://$regserver/v2/simple/manifests/${digest}
}

attach()
{
  # 1. enter the registry container
  # 2. enable 'delete'
  # 3. restart container
  #
  # vi /etc/docker/registry/config.yml
  # 
  # storage:
  #   delete:
  #     enabled: true
  #

  # after deleting the target image,
  # execute garbage collection in container.
  #
  # /bin/registry garbage-collect /etc/docker/registry/config.yml

  # ok
  docker exec -it registry /bin/sh

  # ng
  #docker exec -it registry /bin/bash
}

start()
{
  docker-compose start
}

stop()
{
  docker-compose stop
}

clean()
{
  :
}

args=""
while [ "$#" -ne 0 ]; do
  case $1 in
    -h | --help )
      help
      ;;
    * )
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "$args" ]; then
  help
  exit 1
fi

for arg in $args; do
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    echo "ERROR : $arg is NOT a shell function in this script."
    exit 1
  fi

  $arg
done


