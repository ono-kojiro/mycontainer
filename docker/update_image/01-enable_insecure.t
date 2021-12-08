#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh -y root@${client} \
  sh -s -- $image $container $tag
{
  image=$1
  container=$2
  tag=$3

  cat - << 'JSON' > /etc/docker/daemon.json
{
  "insecure-registries" : [
    "192.168.7.1:5000"
  ]
}
JSON

  systemctl restart docker
  res=$?
  echo ""
  if [ "$res" = "0" ]; then
    echo "ok - docker push passed"
  else
    echo "not ok - docker push failed"
  fi
}
EOS

