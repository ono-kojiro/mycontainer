#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

codename="jammy"
image="jammy"
name="jammy"

tag="latest"
mirror="http://ftp.jaist.ac.jp/pub/Linux/ubuntu/"

archive="${image}.tar.xz"

urls="
  https://raw.githubusercontent.com/SamSaffron/docker/master/contrib/mkimage-debootstrap.sh
"

help()
{
  cat - << EOS
usage : $0 [OPTIONS] [TARGET] [TARGET...]
  options
    -c, --codename        ex. jammy
    -i, --image           ex. jammy-ja
    -t, --tag             ex. 0.0.1

  target:
    fetch
    image
    import
    run
EOS

}

fetch()
{
  for url in $urls; do
    filename=$(basename $url)

    if [ ! -e "$filename" ]; then
      wget $url
    else
      echo skip wget $url
    fi
  done
}

image()
{
  rm -f $archive
  sh ./mkimage-debootstrap.sh -t $archive $codename $mirror
}

import()
{
  docker import $archive $image:$tag
}

run()
{
  docker run -it --rm $image:$tag /bin/bash
}

create()
{
  docker create \
    -it \
    --hostname $name \
    --name $name \
    $image:$tag \
    /bin/bash
}

start()
{
  docker start $name
}

attach()
{
  docker attach $name
}

stop()
{
  docker stop $name
}

clean()
{
  docker rm $name
  docker rmi $image:$tag
}

args=""
while [ "$#" -ne 0 ]; do
  case $1 in
    -h | --help )
      help
      ;;
    -c | --codename )
      shift
      codename="$1"
      ;;
    -i | --image )
      shift
      image="$1"
      ;;
    -t | --tag )
      shift
      tag="$1"
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


