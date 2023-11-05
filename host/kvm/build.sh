#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ret=0

which ansible-playbook > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR : no ansible-playbook command"
  ret=`expr $ret + 1`
fi

if [ "$ret" -ne 0 ]; then
  exit 1
fi

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

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook -K -i hosts.yml -t $tag site.yml
}

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

