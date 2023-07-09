#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="dnssub"

base="jammy"

address="10.0.3.231"
gateway="10.0.3.1"
nameservers=192.168.0.1

alias lxc-create='systemd-run --user --scope -p "Delegate=yes" lxc-create'
alias lxc-start='systemd-run --user --scope -p "Delegate=yes" lxc-start'
alias lxc-attach='systemd-run --user --scope -p "Delegate=yes" lxc-attach --clear-env'
alias lxc-execute='systemd-run --user --scope -p "Delegate=yes" lxc-execute'

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

target:
  clone

  start
  netplan

  dns
EOS

}

all()
{
  network
}

clone()
{
  lxc-copy --name $base -N $name
  
  config="$HOME/.local/share/lxc/$name/config"
  key="lxc.net.0.ipv4.address"
  sed -i -e "s|$key = .*|$key = $address/24|" $config
  key="lxc.net.0.ipv4.gateway"
  sed -i -e "s|$key = .*|$key = $gateway|" $config

  cat - << EOF | lxc-execute -n $name -- tee /etc/netplan/10-lxc.yaml 1>/dev/null
network:
  version: 2
  ethernets:
    eth0:
      addresses:
      - $address/24
      nameservers:
        addresses:
        - $nameservers
      dhcp-identifier: mac
      dhcp4: false
      routes:
      - to: default
        via: $gateway
EOF

}

start()
{
  echo "INFO : start"
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  cmd="lxc-start -n $name"
  echo $cmd
  $cmd
}

ls()
{
  lxc-ls -f
}

test_attach()
{
  lxc-attach -n $name
}

stop()
{
  lxc-stop -n $name
}

status()
{
  lxc-ls -f
}

destroy()
{
  stop
  lxc-destroy -n $name
}

attach()
{
  lxc-attach -n $name
}

mclean()
{
  lxc-stop -n $name -k || true
  lxc-destroy -n $name || true
}

hosts()
{
  ansible-inventory -i groups --list --yaml > hosts.yml
}

dns()
{
  ansible-playbook -i hosts.yml $ansible_options site.yml
}

check()
{
  dns="10.0.3.231"

  dig @$dns dns.sub.example.com +short
  dig @$dns bygzam.sub.example.com +short

  dig -x 10.0.3.231 @$dns +short
  dig -x 10.0.3.8   @$dns +short
}

default()
{
  tags="$1"
  ansible-playbook -i hosts.yml -t $tags $ansible_options site.yml
}

ansible_options=""

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
      ansible_options="$ansible_options $1"
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

