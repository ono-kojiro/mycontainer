#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ansible-inventory -i groups --list --yaml > hosts

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
  ansible-playbook -i hosts site.yml
}

ssh()
{
  command ssh -i id_ed25519 jammy
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

if [ "x$args" = "x" ]; then
  all
fi

for arg in $args; do
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    ansible-playbook -i hosts --tag $arg site.yml
  fi
done

