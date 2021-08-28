#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh root@${client} \
  sh -s -- $image $container $tag
image=$1
container=$2
tag=$3

docker load < ${image}.tar
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker load passed"
else
  echo "not ok - docker load failed"
fi

docker tag ${image} ${tag}
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker tag passed"
else
  echo "not ok - docker tag failed"
fi

docker push ${tag}
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker push passed"
else
  echo "not ok - docker push failed"
fi

EOS

