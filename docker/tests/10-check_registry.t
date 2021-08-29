#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..4"

dpkg -l docker-registry > /dev/null 2>&1
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registry is installed"
else
  echo "not ok - docker-registry is NOT installed"
fi

systemctl is-active docker-registry > /dev/null 2>&1
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker-registry is active"
else
  echo "not ok - docker-registry is NOT active"
fi

ssh -y -o ConnectTimeout=5 root@${client} uname > /dev/null 2>&1
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker client is working"
else
  echo "Bail out! docker client is NOT active"
  exit 1
fi

cat - << 'EOS' | ssh -y root@${client} sh -s > /dev/null 2>&1
{
  cat /etc/docker/daemon.json | grep insecure-registries
}
EOS

res=$?
if [ "$res" = "0" ]; then
  echo "ok - insecure-registries in /etc/docker/daemon.json"
else
  echo "not ok - No insecure-registries in /etc/docker/daemon.json"
fi



