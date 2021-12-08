#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..2"

which docker > /dev/null 2>&1
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker exists"
else
  echo "Bail out! no docker"
  exit $res
fi

docker run -d -p 5000:5000 --restart=always --name registry registry:2
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registry passed"
else
  echo "not ok - docker-registry failed"
fi

