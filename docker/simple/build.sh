#!/bin/sh

# https://stackoverflow.com/questions/25436742/how-to-delete-images-from-a-private-docker-registry

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

pull()
{
  docker pull $regserver/$image
}

manifest()
{
  curl -v --silent http://$regserver/v2/$image/manifests/latest \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    > manifest.json

  cat manifest.json
}

digest()
{
  curl -v --silent \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    http://$regserver/v2/$image/manifests/latest \
    > manifest.json \
    2> manifest.log

  digest=$(cat manifest.log | grep Docker-Content-Digest | awk '{ print($3) }')
  echo digest is $digest
  
  curl -v --silent \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    -X DELETE \
    http://$regserver/v2/$image/manifests/$digest

}

catalog()
{
  curl http://$regserver/v2/_catalog
}

tags()
{
  curl http://$regserver/v2/$name/tags/list
}


destroy()
{
  curl http://$regserver/v2/$image/manifests/latest \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    > manifest.json 2> /dev/null

  cat manifest.json

  digest=$(cat manifest.json | jq -r '.config.digest')

  echo "digest is $digest"
  #curl -v -X DELETE http://$regserver/v2/simple/manifests/${digest}
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
  docker rmi $regserver/$image
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

