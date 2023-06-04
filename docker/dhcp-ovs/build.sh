#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

container="dhcpclient2"
conn="enp0s25"
br0="br0"

help()
{
    usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    init
    bridge
    network
    
    create
    start
    stop
    down
EOS
}

all()
{
  help
}

install()
{
  docker plugin install --grant-all-permissions \
    ghcr.io/devplayer0/docker-net-dhcp:release-linux-amd64
}

init()
{
  cat - << EOF | sudo sh -s
nmcli con add type ethernet ifname $conn con-name $conn
EOF
}

bridge()
{
  cat - << EOF | sudo sh -s
nmcli con add type bridge ifname $br0 con-name $br0
nmcli con mod $br0 ipv4.method auto
nmcli con mod $br0 ipv6.method disabled
nmcli con mod $br0 autoconnect yes

nmcli con add type ethernet con-name $conn ifname $conn
nmcli con mod $conn master $br0

nmcli con down $conn
nmcli con up   $conn

nmcli con down $br0
nmcli con up   $br0
EOF

}

del_bridge()
{
  cat - << EOF | sudo sh -s
nmcli con del $br0
nmcli con del $conn
EOF
  
}

network()
{
  docker network create \
    -d ghcr.io/devplayer0/docker-net-dhcp:release-linux-amd64 \
    --ipam-driver null \
    -o bridge=ovs-br1 \
    -o lease_timeout=60s \
    my-dhcp-ovs
}

net()
{
  network
}

del()
{
  docker network remove my-dhcp-net
}

create()
{
  docker compose up --no-start
}

debug()
{
  sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=0
  sudo sysctl -w net.bridge.bridge-nf-call-iptables=0
  sudo sysctl -w net.bridge.bridge-nf-call-arptables=0
}

start()
{
  docker compose start
}

log()
{
  sudo find /var/lib/docker/plugins/ -name "*.log" -print -exec cat {} \;
}

attach()
{
  docker attach $container
}

stop()
{
  docker compose stop
}

down()
{
  docker compose down
}

ip()
{
  docker inspect \
    --format '{{.Name}} {{ .NetworkSettings.IPAddress }}' \
	$(docker ps -q)
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    -h )
      usage
	  ;;
    -v )
      verbose=1
	  ;;
    *)
	  args="$args $1"
	  ;;
  esac

  shift

done

for target in $args ; do
  LANG=C type $target | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "$target is not a shell function"
  fi
done

