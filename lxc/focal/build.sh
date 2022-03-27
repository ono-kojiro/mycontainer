#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="focal"

template="download"

dist="ubuntu"
release="$name"
arch="amd64"

address="10.0.3.204"
gateway="10.0.3.1"

rootfs="$HOME/.local/share/lxc/$name/rootfs"
  
seckey="id_ed25519_focal"
pubkey="id_ed25519_focal.pub"
  
ssh="command ssh -y"
ssh="$ssh -o UserKnownHostsFile=/dev/null"
ssh="$ssh -o StrictHostKeyChecking=no"
ssh="$ssh -i $seckey"

help()
{
  usage
}

usage()
{
	echo "usage : $0 [options] target1 target2 ..."
    echo ""
    echo "  target:"
    echo "    create/init/start"
    echo "    chpasswd"
    echo "    enable_sshd"
    echo "    update"
    echo "    attach"
    echo "    stop"
    echo "    destroy"
}

all()
{
  create
  init
  start
  chpasswd
  config_network
  update
  enable_sshd
  enable_pubkey_auth
  
  test_ssh
}

create()
{
  lxc-create -t download -n $name -- -d $dist -r $release -a $arch
}

init()
{
  config="$HOME/.local/share/lxc/$name/config"

  cat - << EOS >> $config

lxc.net.0.ipv4.address = $address/24
lxc.net.0.ipv4.gateway = $gateway
EOS

}

start()
{
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  lxc-start -n $name
}

attach()
{
  lxc-attach -n $name --clear-env -- /bin/bash
}

config_network()
{
  cat - << EOS | lxc-attach -n $name --clear-env -- /bin/bash -s $address $gateway
  {
    address=$1
    gateway=$2
    echo "address is $address"
    echo "gateway is $gateway"
    netplan set ethernets.eth0.dhcp4=false
    netplan set ethernets.eth0.addresses=[$address/24]
    netplan set ethernets.eth0.gateway4=$gateway
    netplan set ethernets.eth0.nameservers.addresses=[8.8.8.8]

    netplan apply
  }
EOS

}

update()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    apt -y update
  }
EOS

}

chpasswd()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    echo 'root:secret' | chpasswd
  }
EOS

}

enable_sshd()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    apt -y update
    apt -y install openssh-server

    cat /etc/ssh/sshd_config | grep 'PermitRootLogin yes' > /dev/null
    if [ $? -ne 0 ]; then
      echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
      systemctl restart sshd
    fi
  }
EOS

}

enable_pubkey_auth()
{
  rm -f ./id_ed25519_focal*
  
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  }
EOS

  ssh-keygen -t ed25519 -f $seckey -N ''
  cat $pubkey | lxc-attach -n $name --clear-env -- \
    tee /root/.ssh/authorized_keys
}

keygen()
{
  enable_pubkey_auth
}

test_ssh()
{
  command ssh -y \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -i id_ed25519_focal root@$address ip addr
}

enable_sssd()
{
  cp -f ./sssd.conf $rootfs/tmp/
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    apt -y install sssd-ldap oddjob-mkhomedir
    cp -f /tmp/sssd.conf /etc/sssd/sssd.conf
    chmod 600 /etc/sssd/sssd.conf

    systemctl restart sssd

    pam-auth-update --enable mkhomedir

  }
EOS

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


delegate()
{
    systemd-run --unit=myshell --user --scope \
        -p "Delegate=yes" \
    lxc-start -n $container
}

ls()
{
	lxc-ls -f
}

attach()
{
	#lxc-attach -n $container -- /bin/sh
	lxc-attach -n $container -- /bin/bash
}

mclean()
{
  lxc-stop -n $name -k
  lxc-destroy -n $name
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

for arg in $args; do
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    echo "ERROR : $arg is not shell function"
    exit 1
  fi
done

