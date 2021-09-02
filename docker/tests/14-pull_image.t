#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh -y root@${client} \
  sh -s -- $image $container $tag
image=$1
container=$2
tag=$3

docker pull ${tag}
EOS

res=$?
echo ""
if [ "$res" = "0" ]; then
  echo "ok - docker pull ${tag} passed"
else
  echo "not ok - docker pull ${tag} failed"
fi

