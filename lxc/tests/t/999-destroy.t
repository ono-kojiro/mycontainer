#!/bin/sh

user=root
host=192.168.7.2

ssh="ssh -y"
ssh="$ssh -o StrictHostKeyChecking=no"
ssh="$ssh -o ConnectTimeout=3"

echo "1..1"

cat - << 'EOS' | $ssh ${user}@${host} sh -s
  lxc-destroy -n lxc1
  res=$?
  if [ "$res" = "0" ] ; then
    echo "ok"
  else
    echo "not ok"
  fi
EOS

