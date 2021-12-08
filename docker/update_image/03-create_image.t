#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat create_image.sh | ssh root@${client} sh -s -- -n myimage
res=$?
if [ "$res" = "0" ]; then
  echo "ok - create_image.sh"
else
  echo "not ok - create_image.sh"
fi

