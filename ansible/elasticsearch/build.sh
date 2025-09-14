#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...
EOS

}

all()
{
  deploy
}

clean()
{
  ansible-playbook -i hosts.yml clean.yml
}

hosts()
{
  ansible-inventory -i template.yml --list --yaml > hosts.yml
}

install()
{
  ansible-playbook $flags -i hosts.yml -t install site.yml
}


deploy()
{
  ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t ${tag} site.yml
}

destroy()
{
  ansible-playbook $flags -i hosts.yml destroy.yml
}

test()
{
  addr=`cat ./.netrc | grep -e '^machine' | awk '{ print $2 }'`
  curl -k --netrc-file ./.netrc https://${addr}:9200
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
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

