#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh root@${client} sh -s -- $image $container
image=$1
container=$2

docker rm $container
EOS

res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker rm passed"
else
  echo "not ok - docker rm failed"
fi

