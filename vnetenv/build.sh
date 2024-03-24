#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

inventory="hosts.yml"
playbook="site.yml"

prepare()
{
  :
}

hosts()
{
  ansible-inventory -i template.yml --list --yaml > ${inventory}
}

help()
{
  usage
}

usage()
{
  echo "usage : $0 [options] target1 target2 ..."
cat - << EOS
  target:
    deploy
EOS
}

all()
{
  deploy
}

deploy()
{
  ansible-playbook -K -i ${inventory} ${playbook}
}

default()
{
  tag=$1
  ansible-playbook -K -i ${inventory} -t ${tag} ${playbook}
}

list()
{
  virsh net-list --all
}

hosts

if [ -z "$args" ]; then
  all
fi

for arg in $args; do
  LANG=C type $arg 2>&1 | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    default $arg
  fi
done

