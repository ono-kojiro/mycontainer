#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh root@${client} sh -s -- $image $container
{
  image=$1
  container=$2

  docker start $container
}
EOS

res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker start passed"
else
  echo "not ok - docker start failed"
fi

