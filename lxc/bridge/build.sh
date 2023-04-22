#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

# References

# https://ytsuboi.jp/archives/642
# https://faq.interlink.or.jp/faq2/View/wcDisplayContent.aspx?id=761

# Br0 for LXC
# https://sites.google.com/site/takuminews/linux-1/ubuntu-lxc/br0-for-lxc

# Network Bridge
# https://wiki.archlinux.jp/index.php/%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E3%83%96%E3%83%AA%E3%83%83%E3%82%B8

#                                               +-----------+
#                                     +---------+ client PC |
#                                     |         +-----------+
#         +----------------+          |
#         |       NAT      |      +--------+    +-----------+
# net ----| wlan0     eth0 |------| switch |----| client PC |
#         |                |      +--------+    +-----------+
#         +----------------+          |
#                                     |         +-----------+
#                                     +---------+ client PC |
#                                               +-----------+
#     
#  wlan0 : 192.168.0.98
#  eth0  : 192.168.10.1

addr="192.168.10.1"

help()
{
  usage
}

addbr()
{
  sudo brctl addbr br0
}

addif()
{
  sudo brctl addif br0 eth0
}

change()
{
  sudo nmcli con down eth0
  sudo nmcli con up   br0
}

modify()
{
  sudo nmcli con modify br0 ipv4.method manual ipv4.addresses "$addr/24"
  sudo nmcli con modify br0 ipv4.dns 8.8.8.8
  sudo nmcli con modify br0 connection.autoconnect no
  sudo ip addr del $addr/24 dev eth0
}

show()
{
  brctl show
}

unchange()
{
  sudo ip addr del $addr/24 dev br0
  sudo ip addr add $addr/24 dev eth0
}

down()
{
  sudo nmcli con down br0
  sudo nmcli con up   eth0
}

restart()
{
  nmcli con reload
  down
  up
}

log()
{
  nmcli con show br0 > br0.log
  nmcli con show lxcbr0 > lxcbr0.log
}

delif()
{
  sudo brctl delif br0 eth0
}

delbr()
{
  sudo ip link set down dev br0
  sudo brctl delbr br0
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

  target:
    network:
      addbr/addif/change/modify/unchange/delif/delbr
EOS

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
    echo "ERROR : $arg is not shell function"
    exit 1
  fi
done

