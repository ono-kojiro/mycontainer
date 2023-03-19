#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

hosts="hosts"
site_yml="site.yml"

help()
{
  usage
}

usage()
{
  echo "usage : $0 [options] target1 target2 ..."
cat - << EOS
  target:
    all
EOS
}

all()
{
  ansible
}

status()
{
  :
}

ansible()
{
  if [ "$verbose" -ne 0 ]; then
    opts="-v"
  fi
  ansible-playbook -i $hosts $opts $site_yml
}

default()
{
  tag=$1

  if [ "$verbose" -ne 0 ]; then
    opts="-v"
  fi
  ansible-playbook -i $hosts -t $tag $opts $site_yml
}

list()
{
  ansible-playbook -i $hosts --list-tags $site_yml
}

verbose=0
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
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

