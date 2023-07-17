#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

which ansible-playbook >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo ERROR: no ansible-playbook command
  exit 1
fi

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
    clean
EOS
}

all()
{
  hosts
}

hosts()
{
  ansible-inventory -i groups.ini --list --yaml > hosts.yml
}

enable()
{
  ansible-playbook -K -i hosts.yml enable_bridge.yml
}

disable()
{
  ansible-playbook -K -i hosts.yml disable_bridge.yml
}

dhcpd()
{
  ansible-playbook -K -i hosts.yml dhcpd.yml
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
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    echo "ERROR : $arg is not shell function"
    exit 1
  fi
done

