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

  iperf3 -c localhost -t 3
}

EOS

res=$?
echo ""
if [ "$res" = "0" ]; then
  echo "ok - iperf3 -c passed"
else
  echo "not ok - iperf3 -c failed"
fi

