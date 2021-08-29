#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..1"

cat - << 'EOS' | ssh root@${client} sh -s
{
  docker image list \
    --format "table {{.ID}}\t{{.Repository}}" > images.txt
  res=$?

  cat images.txt
  if [ "$res" = "0" ]; then
    echo "ok - docker image list passed"
  else
    echo "not ok - docker image list failed"
  fi

  cat images.txt | grep -v -e '^IMAGE ID' | awk '{ print $2 }' \
    | xargs docker rmi || true

  rm -f images.txt
}

EOS

