#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..3"

cat - << 'EOS' | ssh root@${client} sh -s
{
  ids=`docker ps -q`
  if [ -z "$ids" ]; then
    echo "ok - no process to kill"
  else
    docker kill $ids
    res=$?

    if [ "$res" = "0" ]; then
      echo "ok - docker kill passed"
    else
      echo "not ok - docker kill failed"
    fi
  fi
}
EOS


cat - << 'EOS' | ssh root@${client} sh -s
{
  ids=`docker ps -a -q`
  if [ -z "$ids" ]; then
    echo "ok - no container to remove"
  else
    docker rm -f $ids
    res=$?

    if [ "$res" = "0" ]; then
      echo "ok - docker remove passed"
    else
      echo "not ok - docker remove failed"
    fi
  fi
}
EOS


cat - << 'EOS' | ssh root@${client} sh -s
{
  ids=`docker images -q`
  if [ -z "$ids" ]; then
    echo "ok - no image to remove"
  else
    docker rmi $ids
    res=$?

    if [ "$res" = "0" ]; then
      echo "ok - docker rmi passed"
    else
      echo "not ok - docker rmi failed"
    fi
  fi
}
EOS

