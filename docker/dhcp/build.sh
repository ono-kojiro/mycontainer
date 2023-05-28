#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

release="jammy"

image="$release"
container="$release"

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
nmcli con modify enp0s25 master $br0 slave-type bridge
nmcli con down $conn
nmcli con up   $conn

nmcli con down $br0
nmcli con up   $br0
EOF

}

network()
{
  docker network create \
    -d ghcr.io/devplayer0/docker-net-dhcp:release-linux-amd64 \
    --ipam-driver null \
    -o bridge=$br0 \
    -o lease_timeout=60s \
    my-dhcp-net
}

del()
{
  docker network remove my-dhcp-net
}

create()
{
  docker compose up --no-start
}

start()
{
  docker compose start
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

