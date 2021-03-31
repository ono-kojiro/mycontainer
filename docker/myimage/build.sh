#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name=myimage

build()
{
  rm -rf tmp
  mkdir -p tmp
  docker build --tag $name .
  rm -rf tmp
}

run()
{
  docker run \
    -it \
    --rm \
    -v /bin:/bin \
    -v /lib:/lib \
    -v /usr/bin:/usr/bin \
    -v /usr/lib:/usr/lib \
    -v /sbin:/sbin \
    --network host \
    $name \
    /bin/bash
}

mynet()
{
  docker run \
    -it \
    --rm \
    -v /bin:/bin \
    -v /lib:/lib \
    -v /usr/bin:/usr/bin \
    -v /usr/lib:/usr/lib \
    -v /sbin:/sbin \
    --network mynet \
    --ip 192.168.7.9 \
    $name \
    /bin/bash
}

for target in "$@" ; do
  LANG=C type $target | grep function > /dev/null 2>&1
  res=$?
  if [ "x$res" = "x0" ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done


