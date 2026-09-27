#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

playbook_yml="agent.yml"
inventory_yml="inventory.yml"
hosts_yml="hosts.yml"

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] [target] ...

  target:
    deploy
EOS

}

all()
{
  deploy
}

hosts()
{
  ansible-inventory -i $inventory_yml --list --yaml > $hosts_yml
}

deploy()
{
  ansible-playbook $flags -i $hosts_yml $playbook_yml
}

default()
{
  tag="$1"
  ansible-playbook $flags -i $hosts_yml -t $tag $playbook_yml
}


destroy()
{
  ansible-playbook $flags -i $hosts_yml -t destroy $playbook_yml
}

hosts

args=""
tags=""

while [ $# -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
    -t )
      shift
      tags="$tags $1"
      ;;
    -*)
      flags="$flags $1"
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
  target=`echo $arg | tr '-' '_'`
  num=`LANG=C type $target | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $target
  else
    default $target
  fi
done

