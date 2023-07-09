#!/bin/sh

#set -e

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
  
seckey="id_ed25519"
pubkey="id_ed25519.pub"

ssh_opts=""
ssh_opts="$ssh_opts -o UserKnownHostsFile=/dev/null"
ssh_opts="$ssh_opts -o StrictHostKeyChecking=no"
ssh_opts="$ssh_opts -i $seckey"

alias systemd-run='systemd-run --user --scope -p "Delegate=yes"'
alias lxc-create='systemd-run lxc-create'
alias lxc-start='systemd-run lxc-start'
alias lxc-attach='systemd-run lxc-attach --clear-env'

ret=0

which ansible-playbook > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR : no ansible-playbook command"
  ret=`expr $ret + 1`
fi

if [ "$ret" -ne 0 ]; then
  exit 1
fi

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

target:
  create
  start
  set_locale
  chpasswd
  config_network
  update
  enable_sshd
  enable_pubkey_auth
  test_ssh

  ssh_root

  sssd
  pubkey

  ssh_user
EOS

}

all()
{
  create
  start
  set_locale
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

  init
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
 
EOS

}

start()
{
  echo "INFO : start"
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  cmd="lxc-start -n $name -l info -o jammy.log"
  echo $cmd
  $cmd
}

debug()
{
  lxc-start -n $name -l debug -o ${name}.log
}

set_locale()
{
  echo "INFO : set locale"

  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    
    locale-gen ja_JP.UTF-8
    localectl set-locale LANG=ja_JP.UTF-8
    apt-get -y install language-pack-ja
  }
EOS

}

test_attach()
{
  #lxc-attach -n $name -- ps
  lxc-attach -n $name
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
    #export DEBIAN_FRONTEND=noninteractive
    apt-get -y update
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
    apt-get -y update
    apt-get -y install openssh-server

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
  rm -f $pubkey $seckey
  
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  }
EOS

  ssh-keygen -t ed25519 -f $seckey -N ''
  cat $pubkey | lxc-attach -n $name --clear-env -- \
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

ssh_root()
{
  command ssh -y $ssh_opts root@$address
}

ssh_user()
{
  command ssh $address
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
  lxc-stop -n $name -k > /dev/null 2>&1 || true
  lxc-destroy -n $name > /dev/null 2>&1 || true
  rm -f id_ed25519*
}

hosts()
{
  ansible-inventory -i groups --list --yaml > hosts.yml
}

native()
{
  ansible-playbook -i hosts.yml native.yml
}

virtual()
{
  ansible-playbook -i hosts.yml virtual.yml
}

keys()
{
  ansible-playbook -i hosts.yml -t keys virtual.yml
}



slapd()
{
  ansible-playbook -i hosts.yml slapd-ldapscripts.yml
}

adduser()
{
  ansible-playbook -i hosts.yml addusers.yml
}

sssd()
{
  ansible-playbook -i hosts.yml sssd.yml
}

pubkey()
{
  ansible-playbook -i hosts.yml ssh-ldap-pubkey.yml
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

