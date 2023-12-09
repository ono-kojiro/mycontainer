#!/bin/sh

# See:
# https://github.com/lxc/lxc-ci/issues/788


top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="kali"

dist="kali"
release="current"
arch="amd64"

template="download"

address="10.0.3.123"
gateway="10.0.3.1"

rootfs="$HOME/.local/share/lxc/$name/rootfs"
  
seckey="id_ed25519"
pubkey="id_ed25519.pub"

ssh_opts=""
ssh_opts="$ssh_opts -o UserKnownHostsFile=/dev/null"
ssh_opts="$ssh_opts -o StrictHostKeyChecking=no"
ssh_opts="$ssh_opts -i $seckey"

#lxc_env='systemd-run --unit=my-unit --user --scope'
#alias lxc-create='$lxc_env -- lxc-create'
#alias lxc-start='$lxc_env -- lxc-start'
#alias lxc-attach='$lxc_env -- lxc-attach --clear-env'

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

target:
  create/init/start
  update
  locale
  chpasswd
  sshd
  update
  stop
  destroy
EOS

}

all()
{
  create
  init
  start
  update
  locale
  chpasswd
  network
  update
  sshd
  enable_pubkey_auth
  test_ssh
}

create()
{
  $lxc_env lxc-create -t download -n $name -- -d $dist -r $release -a $arch
}

init()
{
  echo "INFO : init"
  config="$HOME/.local/share/lxc/$name/config"

  cat - << EOS >> $config

lxc.net.0.ipv4.address = $address/24
lxc.net.0.ipv4.gateway = $gateway

lxc.cgroup.devices.allow =
lxc.cgroup.devices.deny =
 
#lxc.init.cmd = /lib/systemd/systemd systemd.unified_cgroup_hierarchy=1
EOS

}

start()
{
  echo "INFO : start"
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  $lxc_env lxc-start -n $name
}

debug()
{
  #$lxc_env lxc-start -n $name -l debug -o ${name}.log
  command lxc-execute -n $name /bin/bash
}

update()
{
  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y update
  }
EOS
}

locale()
{
  echo "INFO : locale"

  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    echo enable ja_JP.UTF-8
    sed -i -e 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    update-locale LANG=ja_JP.UTF-8
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
  }
EOS

}

network()
{
  echo "INFO : config network"

  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s $address $gateway
{
  address=$1
  gateway=$2
  config="/etc/network/interfaces"
  sed -i -e 's|iface eth0 inet dhcp|iface eth0 inet static|' $config
  sed -i -e "/^iface eth0 inet/a gateway $gateway" $config
  sed -i -e "/iface eth0 inet/a netmask 255.255.255.0" $config
  sed -i -e "/iface eth0 inet/a address $address" $config

  ip addr flush dev eth0
  ifdown eth0
  ifup eth0
}
EOS

}

update()
{
  echo "INFO : update"
  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    #export DEBIAN_FRONTEND=noninteractive
    apt-get -y update
  }
EOS

}

ip()
{
  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    ip addr
  }
EOS

}



chpasswd()
{
  echo "INFO : chpasswd"
  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    echo 'root:secret' | chpasswd
  }
EOS

}

sshd()
{
  echo "INFO : enable sshd"
  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install openssh-server

    config=/etc/ssh/sshd_config

    sed -i -e \
      's|^#\?PermitRootLogin \(.*\)|PermitRootLogin yes|' $config
    
    systemctl restart ssh
    systemctl enable  ssh

    # avoid slow login
    # https://forum.proxmox.com/threads/lxc-container-upgrade-to-bullseye-slow-login-and-apparmor-errors.93064/
    systemctl mask systemd-logind
  }
EOS

}

ssh()
{
  command ssh -i $seckey root@${address}
}

enable_pubkey_auth()
{
  rm -f $pubkey $seckey
  
  cat - << 'EOS' | $lxc_env lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  }
EOS

  ssh-keygen -t ed25519 -f $seckey -N ''
  cat $pubkey | $lxc_env lxc-attach -n $name --clear-env -- \
    tee -a /root/.ssh/authorized_keys
}

keygen()
{
  enable_pubkey_auth
}

test_ssh()
{
  command ssh -y $ssh_opts root@$address -- bash -c 'hostname; hostname -I'
}

ssh()
{
  command ssh -y $ssh_opts root@$address
}


stop()
{
  $lxc_env lxc-stop -n $name
}

status()
{
  $lxc_env lxc-ls -f
}

destroy()
{
  stop
  $lxc_env lxc-destroy -n $name
}

down()
{
  destroy
}


ls()
{
  $lxc_env lxc-ls -f
}

list()
{
  ls
}

attach()
{
  #lxc-attach -n $container -- /bin/sh
  $lxc_env lxc-attach -n $name
}

mclean()
{
  $lxc_env lxc-stop -n $name -k || true
  $lxc_env lxc-destroy -n $name || true
  rm -f id_ed25519*
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

