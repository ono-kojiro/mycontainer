#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

image=myimage
container=mycontainer

help()
{
  echo "usage : $0 <target>"
  echo ""
  echo "  image      create image"
  echo "  network    create network"
  echo "  container  create container"
  echo "  start      start container"
  echo "  attach     attach container"
  echo "  stop       stop container"
  echo ""
  echo "  remove_container"
  echo "  remove_image"
  echo "  remove_network"
  echo ""
  echo "  clean    stop/remove container, remove image"
}

image()
{
  rm -rf tmp
  mkdir -p tmp
  docker build --tag $image .
  rm -rf tmp
}

network()
{
  docker network create \
    -d macvlan \
    --subnet=192.168.7.0/24 \
    --gateway=192.168.7.1 \
    -o parent=macvlan0 \
    macvlan
}

remove_network()
{
  docker network rm macvlan
}

container()
{
  docker create \
    -it \
    --name $container \
    -v /bin:/bin \
    -v /lib:/lib \
    -v /usr/bin:/usr/bin \
    -v /usr/lib:/usr/lib \
    -v /usr/lib64:/usr/lib64 \
    -v /sbin:/sbin \
    --network macvlan \
    $image \
    /bin/bash
}

remove_image()
{
  docker rmi $image
}

test()
{
  docker run \
    -it \
    --rm \
    -v /bin:/bin \
    -v /lib:/lib \
    -v /usr/bin:/usr/bin \
    -v /usr/lib:/usr/lib \
    -v /usr/lib64:/usr/lib64 \
    -v /sbin:/sbin \
    --network host \
    $name \
    /bin/bash
}

start()
{
  docker start $container
}

attach()
{
  echo "Press Ctrl+P, Ctrl+Q to detach container."
  docker attach $container
}

stop()
{
  docker stop $container
}

remove_container()
{
  docker rm $container
}

clean()
{
  stop
  remove_container
  remove_image
  remove_network
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
    -v /usr/lib64:/usr/lib64 \
    -v /sbin:/sbin \
    --network macvlan \
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


