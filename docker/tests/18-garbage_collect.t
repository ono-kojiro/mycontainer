#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

sudo docker-registry garbage-collect /etc/docker/registry/config.yml

res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registory garbage-collect passed"
else
  echo "not ok - docker-registory garbage-collect failed"
fi

