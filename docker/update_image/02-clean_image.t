#!/bin/sh

tc=`basename $0 .t`

. ./config.bashrc

echo "1..2"

cat - << 'EOS' | ssh -y ${client} sh -s
{
  num_cont=`docker ps -a -q | wc -l`
  if [ "$num_cont" = "0" ]; then
    echo "ok - SKIP : no need to docker rm"
  else
    docker rm -f $(docker ps -a -q)
    res=$?
    if [ "$res" = "0" ]; then
      echo "ok - docker rm"
    else
      echo "not ok - docker rm"
    fi
  fi

  num_image=`docker images -q | wc -l`
  if [ "$num_image" = "0" ]; then
    echo "ok - SKIP : no need to docker rmi"
  else
    docker rmi -f $(docker images -q)
    res=$?
    if [ "$res" = "0" ]; then
      echo "ok - docker rmi"
    else
      echo "not ok - docker rmi"
    fi
  fi
}
EOS

