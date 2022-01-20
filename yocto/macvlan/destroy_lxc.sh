#!/bin/sh

remote=192.168.7.2

usage()
{
  echo "$0"
}

while [ $# -ne 0 ]; do
  case $1 in
    -h | --help)
	  usage
	  exit 1
	  ;;
	*)
	  break
	  ;;
  esac

  shift
done

cat - << 'EOS' | ssh -y $remote sh -s
{
  names=`lxc-ls -q`
  for name in $names; do
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
  done
}

EOS

