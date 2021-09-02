#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

docker run -d -p 5000:5000 --restart=always --name registry registry:2

res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registry passed"
else
  echo "not ok - docker-registry failed"
fi

