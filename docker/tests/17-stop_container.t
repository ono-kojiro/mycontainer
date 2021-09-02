#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh root@${client} sh -s
{
  docker ps -a \
    --format "table {{.Image}}\t{{.Names}}\t{{.Status}}" > names.txt
  res=$?

  cat names.txt
  if [ "$res" = "0" ]; then
    echo "ok - docker ps passed"
  else
    echo "not ok - docker ps failed"
  fi

  cat names.txt | grep -v -e '^IMAGE ' | awk '{ print $2 }' \
    | xargs docker stop | true

  rm -f names.txt
}

EOS

