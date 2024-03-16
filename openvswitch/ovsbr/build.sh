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
  ansible-inventory -i groups.yml --list --yaml > hosts.yml
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
  ansible-playbook -K -i $inventory $playbook
}

default()
{
  arg=$1
  ansible-playbook -K -i $inventory ${arg}.yml
}

list()
{
  virsh net-list --all
}

dhcp()
{
  nets=`virsh net-list --name`
  for net in $nets; do
    virsh net-dhcp-leases $net
  done
}

hosts

args=""
while [ $# -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
    * )
      args="$args $1"
      ;;
  esac
  
  shift
done

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

