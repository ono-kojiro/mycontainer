#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

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

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook -i hosts.yml -t $tag site.yml
}

status()
{
  echo "Message-Authenticator = 0x00" | \
    radclient 127.0.0.1:1812 status testing123
}

radtest()
{
  cmd="radtest USERNAME PASSWORD 127.0.0.1 1812 testing123"
  echo $cmd
  command $cmd
}

destroy()
{
   sudo systemctl stop freeradius
   sudo apt -y remove --purge freeradius freeradius-config freeradius-common
   sudo apt -y autoremove
   sudo rm -rf /etc/freeradius
   sudo rm -rf /var/log/freeradius
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

