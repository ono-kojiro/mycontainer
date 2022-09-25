#!/bin/sh

image="simple"
name="simple"

regserver="192.168.0.98:5000"

help()
{
  cat - << EOS
usage : $0 [OPTIONS] [TARGET] [TARGET]...

  target :
    hello      build hello
    build      build image
    tag        create tag
    push       docker push
EOS

}

hello()
{
  gcc -o hello -static hello.c
}

build()
{
  docker build --tag $image .
}

image()
{
  build
}

tag()
{
  docker tag $image $regserver/$image
}

push()
{
  docker push $regserver/$image
}

manifest()
{
  curl http://$regserver/v2/$image/manifests/latest \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    > manifest.json 2> /dev/null

  cat manifest.json
}

delete()
{
  curl http://$regserver/v2/$image/manifests/latest \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    > manifest.json 2> /dev/null

  cat manifest.json

  digest=$(cat manifest.json | jq -r '.config.digest')
  curl -v -X DELETE http://$regserver/v2/simple/manifests/${digest}
}

inspect()
{
  docker inspect $name
}

start()
{
  docker start $name
}

attach()
{
  echo press Ctrl+P, Ctrl+Q to quit
  docker attach $name
}

stop()
{
  docker stop $name
}

remove()
{
  docker rm $name
}

rmi()
{
  docker rmi $image
}

clean()
{
  command rm -f ./hello
  rmi
  remove
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

