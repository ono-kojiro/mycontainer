#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..3"

cat - << 'EOS' | ssh -y root@${client} \
  sh -s -- $image $container $tag
image=$1
container=$2
tag=$3

docker rmi $image
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker rmi $image"
else
  echo "not ok - docker rmi $image"
fi

docker rmi $tag
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker rmi $tag" 
else
  echo "not ok - docker rmi $tag"
fi

docker pull $tag
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker pull $tag" 
else
  echo "not ok - docker pull $tag"
fi

EOS

