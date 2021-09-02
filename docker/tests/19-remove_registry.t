#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..2"

docker stop registry > /dev/null 2>&1
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker stop passed"
else
  echo "not ok - docker stop failed"
fi

docker rm registry > /dev/null 2>&1
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker rm passed"
else
  echo "not ok - docker rm failed"
fi

