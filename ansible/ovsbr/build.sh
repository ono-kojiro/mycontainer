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

add_br()
{
  sudo nmcli con add type ovs-bridge \
    ifname ovsbr60 \
    con-name ovsbr60
}

add_pt()
{
  sudo nmcli con add type ovs-port \
    ifname ovspt60 master ovsbr60 conn.id ovspt60
}

add_if()
{
  sudo nmcli con add type ovs-interface \
    slave-type ovs-port \
    conn.interface ovsbr60 \
    master ovspt60 \
    con-name ovsif60
}

add()
{
  add_br
  add_pt
  add_if

  mod_if
}

mod_if()
{
  sudo nmcli con mod ovsif60 \
    ipv4.method manual \
    ipv4.addresses 192.168.60.253/24 \
    ipv6.method disable

  sudo nmcli con down ovsif60
  sudo nmcli con up   ovsif60
}

mod()
{
  mod_if
}

del_if()
{
  sudo nmcli con del ovsif60
}

del_pt()
{
  sudo nmcli con del ovspt60
}

del_br()
{
  sudo nmcli con del ovsbr60
}

del()
{
  del_if
  del_pt
  del_br
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

