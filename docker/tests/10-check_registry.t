#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..3"

dpkg -l docker-registry
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registry is installed"
else
  echo "not ok - docker-registry is NOT installed"
fi

systemctl is-active docker-registry
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registry is active"
else
  echo "not ok - docker-registry is NOT active"
fi

cat - << 'EOS' | ssh root@${client} sh -s
cat /etc/docker/daemon.json | grep insecure-registries
EOS

res=$?
if [ "$res" = "0" ]; then
  echo "ok - insecure-registries in /etc/docker/daemon.json
else
  echo "not ok - No insecure-registries in /etc/docker/daemon.json
fi



