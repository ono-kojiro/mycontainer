#!/bin/sh

remote=yocto

cat - << 'EOS' | ssh -y $remote sh -s
{
  name="mylxc"
  status=`lxc-ls -f | grep -r '^$name ' | awk '{ print $2 }'`
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

  cmd="lxc-create -t sshd -n $name"
  echo $cmd
  $cmd > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "lxc-create passed"
  else
    echo "lxc-create failed"
  fi

}

EOS

