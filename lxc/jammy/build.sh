#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="jammy"

template="download"

dist="ubuntu"
release="$name"
arch="amd64"

address="10.0.3.224"
gateway="10.0.3.1"

rootfs="$HOME/.local/share/lxc/$name/rootfs"
  
seckey="id_ed25519_${name}"
pubkey="id_ed25519_${name}.pub"

ssh_opts=""
ssh_opts="$ssh_opts -o UserKnownHostsFile=/dev/null"
ssh_opts="$ssh_opts -o StrictHostKeyChecking=no"
ssh_opts="$ssh_opts -i $seckey"

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
  set_locale
  chpasswd
  config_network
  update
  enable_sshd
  enable_pubkey_auth
  test_ssh

  enable_sssd
  test_sssd

  setup_default_user
}

create()
{
  lxc-create -t download -n $name -- -d $dist -r $release -a $arch
}

init()
{
  echo "INFO : init"
  config="$HOME/.local/share/lxc/$name/config"

  cat - << EOS >> $config

lxc.net.0.ipv4.address = $address/24
lxc.net.0.ipv4.gateway = $gateway
EOS

}

start()
{
  echo "INFO : start"
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  lxc-start -n $name
}

set_locale()
{
  echo "INFO : set locale"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    apt -y install language-pack-ja
    locale-gen ja_JP.UTF-8
    localectl set-locale LANG=ja_JP.UTF-8
  }
EOS

}

attach()
{
  lxc-attach -n $name --clear-env -- /bin/bash
}

config_network()
{
  echo "INFO : config_network"

  cat - << EOS | lxc-attach -n $name --clear-env -- /bin/bash -s $address $gateway
  {
    address=$1
    gateway=$2
    echo "address is $address"
    echo "gateway is $gateway"
    netplan set ethernets.eth0.dhcp4=false
    netplan set ethernets.eth0.addresses=[$address/24]
    netplan set ethernets.eth0.routes=[{\"to\":\"default\"\,\"via\":\"$gateway\"}]
    netplan set ethernets.eth0.nameservers.addresses=[8.8.8.8]

    sleep 1s

    netplan apply
  }
EOS

}

update()
{
  echo "INFO : update"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    apt -y update
  }
EOS

}

chpasswd()
{
  echo "INFO : chpasswd"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    echo 'root:secret' | chpasswd
  }
EOS

}

enable_sshd()
{
  echo "INFO : enable_sshd"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
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
  rm -f ./id_ed25519_${name}*
  
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
  ssh -y $ssh_opts root@$address ip addr
}

enable_sssd()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    apt -y install sssd-ldap oddjob-mkhomedir
    apt -y install apt-utils
  }
EOS
  
  scp $ssh_opts \
    ./sssd.conf root@$address:/etc/sssd/sssd.conf

  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    chmod 600 /etc/sssd/sssd.conf
    systemctl restart sssd
    pam-auth-update --enable mkhomedir
  }
EOS

}

test_sssd()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s $USER
  {
    user=$1
    id $user

    gpasswd -a $user sudo
  }
EOS

}

setup_default_user()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s $USER
  {
    user=$1
    mkdir -p /home/$user
    chmod 755 /home/$user
    chown $user:ldapusers /home/$user
    
    mkdir -p  /home/$user/.ssh
    chmod 700 /home/$user/.ssh
    chown $user:ldapusers /home/$user/.ssh
  }
EOS

  cat $HOME/.ssh/id_ed25519.pub | lxc-attach -n $name -- tee $HOME/.ssh/authorized_keys

  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s $USER
  {
    user=$1
    chmod 755 /home/$user/.ssh/authorized_keys
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
  lxc-stop -n $name -k || true
  lxc-destroy -n $name || true
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
  num=`LANG=C type $arg | grep 'function' | wc -l`
  if [ $num -ne 0 ]; then
    $arg
  else
    echo "ERROR : $arg is not shell function"
    exit 1
  fi
done

