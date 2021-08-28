#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"
ssh root@$client uname
res=$?

if [ "$res" = "0" ]; then
  echo "ok"
else
  echo "not ok"
fi

