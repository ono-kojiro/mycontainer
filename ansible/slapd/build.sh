#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""
name=""

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

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
  ansible-inventory -i template.yml --list --yaml > hosts.yml
}

deploy()
{
   ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t $tag site.yml
}

debug()
{
  ansible-playbook $flags -i hosts.yml debug.yml
}

_get_latest_snapshot()
{
  name="$1"
  snap=`virsh snapshot-list "$name" | \
          grep -e '^ ' | \
          tail -n 1 | \
          awk '{ print $1 }'`
  echo $snap
}

revert()
{
  if [ -z "$name" ]; then
    echo "ERROR: no name option"
    exit 1
  fi

  snap=`_get_latest_snapshot $name`
  if [ -z "$snap" ]; then
    echo "ERROR: no snapshot for $name"
    exit 1
  fi

  virsh snapshot-revert $name $snap
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
    -n | --name)
      shift
      name="$1"
      ;;
	-* )
	  flags="$flags $1"
	  ;;
    * )
      args="$args $1"
      ;;
  esac
  
  shift
done

if [ -z "$args" ]; then
  help
  exit 1
fi

for arg in $args; do
  num=`LANG=C type $arg | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

