#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..2"

cat - << 'EOS' > Dockerfile
FROM scratch
ADD ./tmp /tmp/
CMD ["/usr/bin/iperf3", "-s"]
EOS

scp Dockerfile root@${client}:/home/root/
res=$?

if [ "$res" = "0" ]; then
  echo "ok - scp Dockerfile passed"
else
  echo "not ok - scp Dockerfile failed"
  echo "Bailout!"
fi

rm -f Dockerfile

cat - << 'EOS' | ssh root@${client} sh -s -- $image
{
  image=$1

  rm -rf tmp
  mkdir tmp
  docker build --tag $image .
  res=$?
  if [ "$res" = "0" ]; then
    echo "ok - docker build passed"
  else
    echo "not ok - docker build failed"
  fi

  rm -f Dockerfile
  rm -rf tmp
}

EOS


