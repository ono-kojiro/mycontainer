#!/bin/sh

remote=192.168.7.2

usage()
{
  echo "$0 --name contname --template tempname"
}

while [ $# -ne 0 ]; do
  case $1 in
    -h | --help)
	  usage
	  exit 1
	  ;;
	-n | --name)
	  shift
	  name=$1
	  ;;
	-t | --template)
	  shift
	  template=$1
	  ;;
	-a | --address)
	  shift
	  addr=$1
	  ;;
	*)
	  break
	  ;;
  esac

  shift
done

template=${template:="busybox"}
name=${template:="name"}
addr=${addr:="192.168.7.5"}

cat - << 'EOS' | ssh -y $remote sh -s -- $template $name $addr
{
  template=$1
  name=$2
  addr=$3

  status=`lxc-ls -f | grep -r "^$name " | awk '{ print $2 }'`
  cmd="lxc-stop -n $name"
  if [ "$status" = "RUNNING" ]; then
	echo $cmd
	$cmd
  else
    echo "skip : $cmd"
  fi

  cmd="lxc-destroy -n $name"
  if [ -d /var/lib/lxc/$name ]; then
	echo $cmd
	$cmd
  else
    echo "skip : $cmd"
  fi

  cmd="lxc-create -t $template -n $name"
  echo $cmd
  $cmd > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "lxc-create passed"
  else
    echo "lxc-create failed"
  fi

  config=/var/lib/lxc/$name/config
  ### common
  sed -i.bak -e \
	's|^lxc.network.type = empty|#lxc.network.type = empty|' \
	$config

  # revise errors of 'start'
  sed -i.bak -e \
	's|^lxc.mount.entry = /dev dev|#lxc.mount.entry = /dev dev|' \
	$config

  {
    echo "lxc.network.type = macvlan"
    echo "lxc.network.link = macvlan0"
    echo "lxc.network.macvlan.mode = bridge"
    echo "lxc.network.flags = up"
    echo "lxc.network.ipv4.address = $addr/24"
    echo "lxc.network.ipv4.gateway = 192.168.7.2"
  } >> $config

  if [ "$template" = "busybox" ]; then
  {
    echo "lxc.mount.entry = /usr/bin usr/bin none ro,bind 0 0"
    echo "lxc.mount.entry = /sbin sbin none ro,bind 0 0"
  } >> $config
  fi

  cmd="lxc-start -n $name"
  echo $cmd
  $cmd

}

EOS

