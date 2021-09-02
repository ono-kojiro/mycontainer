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

  docker run \
	--rm -t \
	-d \
    -v /bin:/bin \
    -v /usr/bin:/usr/bin \
    -v /lib:/lib \
    -v /usr/lib:/usr/lib \
    --network host \
    $tag
}

EOS

res=$?
echo ""
if [ "$res" = "0" ]; then
  echo "ok - docker run passed"
else
  echo "not ok - docker run failed"
fi

