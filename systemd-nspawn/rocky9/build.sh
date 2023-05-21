#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

# Host:      Ubuntu 22.04
# Container: Rocky Linux 9

release="rocky9"

image="${release}"
name="${release}-02"
    
reposdir=`pwd`/rocky
setopt="reposdir=${reposdir}"
#config=`pwd`/rocky/rocky.repo

help()
{
  usage
}

usage()
{
	cat - << EOS
usage : $0 [options] target1 target2 ...

  target
    prepare

    build
    network

    run/login

    list
    start/stop/restart
    destroy
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

build()
{
  cat - << EOF | sudo -- sh -s
{
  cd /var/lib/machines
  dnf -y --releasever=9 \
    --nogpgcheck \
    --setopt=${setopt} \
    --installroot=/var/lib/machines/${name} \
    groupinstall "Base"

  dnf -y --releasever=9 \
    --nogpgcheck \
    --setopt=${setopt} \
    --installroot=/var/lib/machines/${name} \
    install passwd dnf epel-release vim-minimal
  
  dnf -y --releasever=9 \
    --nogpgcheck \
    --setopt=${setopt} \
    --installroot=/var/lib/machines/${name} \
    install systemd-resolved systemd-networkd
}
EOF

}

network()
{
  # use macvlan
  # (same as 'sudo systemctl edit systemd-nspawn@${name}')
  config_dir="/etc/systemd/system/systemd-nspawn@${name}.service.d"
  config="${config_dir}/override.conf"
  sudo mkdir -p ${config_dir}

  cat - << EOF | sudo tee ${config}
[Service]
ExecStart=
ExecStart=systemd-nspawn -b --network-macvlan=macvlan0 -U --private-users=0 --private-users-chown -D /var/lib/machines/%i
EOF
  
  # enable DHCP
  installroot="/var/lib/machines/${name}"
  config="${installroot}/etc/systemd/network/mv-macvlan0.network"

  cat - << EOF | sudo tee ${config}
[Match]
Name=mv-macvlan0

[Network]
DHCP=yes
EOF
  
}

destroy()
{
  sudo rm -rf /var/lib/machines/${name}
}

list()
{
  machinectl list-images
}

status()
{
  #machinectl list-images
  systemctl status systemd-nspawn@${name}
}

run()
{
  sudo -- sh -c "cd /var/lib/machines; systemd-nspawn -D $name"
}

start()
{
  sudo systemctl start systemd-nspawn@${name}
}

restart()
{
  sudo systemctl restart systemd-nspawn@${name}
}

stop()
{
  sudo systemctl stop systemd-nspawn@${name}
}

login()
{
  sudo machinectl login $name
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

