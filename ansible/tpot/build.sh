#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="provider"

dist="ubuntu"
release="jammy"
arch="amd64"

#link_dev=eth0
link_dev=br0

address=192.168.10.123
gateway=192.168.10.1
nameserver=192.168.0.1

rootfs="$HOME/.local/share/lxc/$name/rootfs"
  
pubkey="$HOME/.ssh/id_ed25519.pub"
seckey="$HOME/.ssh/id_ed25519"

ssh_opts=""
ssh_opts="$ssh_opts -o UserKnownHostsFile=/dev/null"
ssh_opts="$ssh_opts -o StrictHostKeyChecking=no"
ssh_opts="$ssh_opts -i $seckey"

alias systemd-run='systemd-run --user --scope -p "Delegate=yes"'
alias lxc-create='systemd-run lxc-create'
alias lxc-start='systemd-run lxc-start'
alias lxc-attach='systemd-run lxc-attach --clear-env'

ret=0

#which ansible-playbook > /dev/null 2>&1
#if [ $? -ne 0 ]; then
#  echo "ERROR : no ansible-playbook command"
#  ret=`expr $ret + 1`
#fi

#if [ "$ret" -ne 0 ]; then
#  exit 1
#fi

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
  netplan
  update
  enable_sshd
  send_pubkey
EOS

}

all()
{
  create
  enable_static
  start
  update
  enable_sshd
  send_pubkey
}

prepare()
{
  sudo apt -y install ansible
}

create()
{
  lxc-create -t download -n $name -- -d $dist -r $release -a $arch
  _init
}

_init()
{
  echo "INFO : init"
  config="$HOME/.local/share/lxc/$name/config"

  cat - << EOS >> $config

#lxc.net.0.ipv4.address = x.x.x.x/xx
#lxc.net.0.ipv4.gateway = x.x.x.x

lxc.cgroup.devices.allow =
lxc.cgroup.devices.deny =
 
EOS

}

enable_static()
{
  echo "enable static address"
  config="$HOME/.local/share/lxc/$name/config"
  key="lxc.net.0.ipv4.address"
  sed -i -e "s|^#\?$key = .*|$key = $address/24|" $config
  key="lxc.net.0.ipv4.gateway"
  sed -i -e "s|^#\?$key = .*|$key = $gateway|" $config

  key="lxc.net.0.link"
  sed -i -e "s|$key = .*|$key = $link_dev|" $config

  cat - << EOF | lxc-execute -n $name -- tee /etc/netplan/10-lxc.yaml 1>/dev/null
network:
  version: 2
  ethernets:
    eth0:
      addresses:
      - $address/24
      nameservers:
        addresses:
        - $nameserver
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
  #cmd="lxc-start -n $name -l info -o jammy.log"
  cmd="lxc-start -n $name"
  echo $cmd
  $cmd
}

enable_dhcp()
{
  echo "enable dhcp"
  config="$HOME/.local/share/lxc/$name/config"
  key="lxc.net.0.ipv4.address"
  sed -i -e "s|^$key = .*|#$key = $address/24|" $config
  key="lxc.net.0.ipv4.gateway"
  sed -i -e "s|^$key = .*|#$key = $gateway|" $config
  
  key="lxc.net.0.link"
  sed -i -e "s|$key = .*|$key = $link_dev|" $config

  cat - << EOF | lxc-execute -n $name -- tee /etc/netplan/10-lxc.yaml 1>/dev/null
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF
}

netplan()
{
  echo "INFO : netplan"

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
    apt-get -y update
  }
EOS

}

enable_sshd()
{
  echo "INFO : enable_sshd"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install openssh-server

    cat /etc/ssh/sshd_config | grep 'PermitRootLogin yes' > /dev/null
    if [ $? -ne 0 ]; then
      echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
      systemctl restart sshd
    fi
  }
EOS

}

send_pubkey()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  }
EOS

  cat $pubkey | lxc-attach -n $name --clear-env -- \
    tee -a /root/.ssh/authorized_keys
}

ssh()
{
  command ssh -y $ssh_opts root@$address
}

stop()
{
  lxc-stop -n $name
}

snap()
{
  lxc-snapshot -n $name -N snap0
}

restore()
{
  lxc-snapshot -n $name -r snap0
}

list()
{
  lxc-snapshot -n $name --list
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

down()
{
  destroy
}

attach()
{
  lxc-attach -n $name
}

clean()
{
  ansible-playbook -K -i hosts.yml clean.yml
}

mclean()
{
  lxc-stop -n $name -k > /dev/null 2>&1 || true
  lxc-destroy -n $name > /dev/null 2>&1 || true
  rm -f id_ed25519*
}

hosts()
{
  ansible-inventory -i groups.yml --list --yaml > hosts.yml
}

deploy()
{
  ansible-playbook -K -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook -K -i hosts.yml -t $tag site.yml
}

#hosts

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
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

