#!/bin/sh

user=root
host=192.168.7.2

ssh="ssh -y"
ssh="$ssh -o StrictHostKeyChecking=no"
ssh="$ssh -o ConnectTimeout=3"

echo "1..2"

$ssh ${user}@${host} uname -a
res=$?

if [ "$res" = "0" ] ; then
  echo "ok"
else
  echo "not ok"
fi

cat - << 'EOS' | $ssh ${user}@${host} sh -s
  lxc-create -t sshd -n lxc1
  res=$?
  if [ "$res" = "0" ] ; then
    echo "ok"
  else
    echo "not ok"
  fi

  config=/var/lib/lxc/lxc1/config
  sed -i.bak 's|^lxc.network.type = empty|#lxc.network.type = empty|' \
    $config
  sed -i.bak 's|^lxc.mount.entry = /dev|#lxc.mount.entry = /dev|' \
    $config
  sed -i.bak 's|^lxc.mount.entry = /usr/share|#lxc.mount.entry = /usr/share|' \
    $config
  sed -i.bak 's|^lxc.mount.entry = /etc/init.d|#lxc.mount.entry = /etc/init.d|' \
    $config

  echo "lxc.network.type = macvlan" >> $config
  echo "lxc.network.link = macvlan0" >> $config
  echo "lxc.network.macvlan.mode = bridge" >> $config
  echo "lxc.network.flags = up" >> $config
  echo "lxc.network.ipv4.address = 192.168.7.5/24" >> $config
  echo "lxc.network.ipv4.gateway = 192.168.7.2" >> $config

EOS

