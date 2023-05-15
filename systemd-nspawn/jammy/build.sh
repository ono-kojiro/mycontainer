#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

release="jammy"

image="${release}"
name="${release}"

help()
{
  usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    debootstrap
EOS
}

all()
{
  help
}

prepare()
{
  sudo apt-get -y install debootstrap
}

image()
{
  url="http://jp.archive.ubuntu.com/ubuntu/"

  cat - << EOF | sudo -- sh -s
{
  cd /var/lib/machines
  /usr/sbin/debootstrap --include=systemd-container \
    --components="main,universe" \
    $release $name $url
}
EOF

}

status()
{
  #machinectl list-images
  sudo systemctl status systemd-nspawn@${name}
}

run()
{
  sudo -- sh -c "cd /var/lib/machines; systemd-nspawn -D $name"
}

edit()
{
  sudo systemctl edit systemd-nspawn@${name}
}

start()
{
  sudo systemctl start systemd-nspawn@${name}
}

restart()
{
  sudo systemctl restart systemd-nspawn@${name}
}


login()
{
  sudo machinectl login $name
}

network()
{
  echo "add follogin code to /etc/netplan/99-custom.yaml and restart container"

  cat - << EOF
network:
  version: 2
  ethernets:
    mv-macvlan0:
      dhcp4: true
EOF

}


if [ $# -eq 0 ]; then
  usage
  exit 1
fi

args=""

while [ $# -ne 0 ]; do
  case "$1" in
    h)
      usage
	  ;;
    v)
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

