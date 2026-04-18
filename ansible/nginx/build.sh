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
  ansible-inventory -i inventory.yml --list --yaml > hosts.yml
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

check()
{
  curl -k https://localhost/
  curl -k https://localhost/couchdb/
  curl -k https://localhost/couchdb/_utils/
}

simple()
{
  cmd="curl -k https://localhost/couchdb/"
  echo "$" $cmd
  $cmd
}

debug()
{
  cmd="curl -k https://localhost/couchdb/"
  echo "$" $cmd
  $cmd
  cmd='curl -k -H "X-API-Key: KEY_APP1_ABC123" https://localhost/couchdb/mydb'
  echo "$" $cmd
  $cmd
  cmd='curl -k -H "X-API-Key: KEY_APP1_ABC123" https://localhost/couchdb/mydb/'
  echo "$" $cmd
  $cmd
  cmd='curl -k -H "X-API-Key: KEY_APP1_ABC123" https://localhost/couchdb/example'
  echo "$" $cmd
  $cmd
  cmd='curl -k -H "X-API-Key: KEY_APP1_ABC123" https://localhost/couchdb/example/'
  echo "$" $cmd
  $cmd
}

test()
{
  prove test.sh
  cat result.log
}

hosts

args=""
while [ "$#" -ne 0 ]; do
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
  num=`LANG=C type $arg | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

