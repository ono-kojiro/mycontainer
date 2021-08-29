#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh root@${client} sh -s -- $image $container
{
  image=$1
  container=$2

  docker ps -a \
     --format "table {{.Image}}\t{{.Names}}" \
     | grep $image | grep $container
  res=$?
  if [ "$res" = "0" ]; then
    docker rm $container
  fi

  docker create \
    -it \
    --name $container \
    -v /bin:/bin \
    -v /lib:/lib \
    -v /usr/bin:/usr/bin \
    -v /usr/lib:/usr/lib \
    -v /usr/lib64:/usr/lib64 \
    -v /sbin:/sbin \
    --network host \
    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    $image \
    /bin/bash
}

EOS

res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker create passed"
else
  echo "not ok - docker create failed"
fi

