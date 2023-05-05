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

alias lxc-create='systemd-run --user --scope -p "Delegate=yes" lxc-create'
alias lxc-start='systemd-run --user --scope -p "Delegate=yes" lxc-start'
alias lxc-attach='systemd-run --user --scope -p "Delegate=yes" lxc-attach --clear-env'

help()
{
  usage
}

usage()
{
  cat << "EOS"
usage : $0 [options] target1 target2 ...

target:
  create/init/start
  chpasswd
  set_locale
  enable_sshd
  update
  stop
  destroy

  config_network
  enable_sshd/enable_pubkey_auth/test_ssh
  enable_sssd/test_sssd

  setup_default_user
  setup_user_config
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

  #enable_sssd
  #test_sssd

  #setup_default_user
  #setup_user_config

  #install_devel
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
 
#lxc.init.cmd = /lib/systemd/systemd systemd.unified_cgroup_hierarchy=1
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
  lxc-attach -n $name -- ps
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

ssh()
{
  command ssh -y $ssh_opts root@$address
}


check()
{
  ssh -y $ssh_opts root@$address ip link show eth0
  if [ $? -eq 0 ]; then
    echo "ssh connection passed"
  else
    echo "ssh connection failed"
  fi
}

enable_sssd()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install sssd-ldap oddjob-mkhomedir
    apt-get -y install apt-utils
  }
EOS
  
  cat - << 'EOS' | lxc-attach -n $name -- tee /etc/sssd/sssd.conf
[sssd]
debug_level = 9
config_file_version = 2
services = nss, pam
domains = LDAP

[domain/LDAP]
ldap_schema = rfc2307
cache_credentials = true

id_provider     = ldap
auth_provider   = ldap
chpass_provider = ldap

ldap_uri = ldap://10.0.3.1
ldap_search_base = dc=example,dc=com

ldap_chpass_uri = ldap://10.0.3.1

ldap_id_use_start_tls = true
ldap_tls_reqcert = never

ldap_user_search_base  = ou=Users,dc=example,dc=com
ldap_group_search_base = ou=Groups,dc=example,dc=com

access_provider = simple
simple_allow_groups = ldapusers

enumerate = true
EOS

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
 
  if [ -e "$HOME/.ssh/id_ed25519.pub" ]; then 
    cat $HOME/.ssh/id_ed25519.pub | \
      lxc-attach -n $name -- tee -a $HOME/.ssh/authorized_keys
  fi

  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s $USER
  {
    user=$1
    chmod 755 /home/$user/.ssh/authorized_keys
  }
EOS
}

setup_user_config()
{
  userfiles=""
  userfiles="$userfiles $HOME/.vimrc"
  userfiles="$userfiles $HOME/.tmux.conf"
  userfiles="$userfiles $HOME/.gitconfig"
  userfiles="$userfiles $HOME/.profile"
  userfiles="$userfiles $HOME/.bashrc"
  userfiles="$userfiles $HOME/.git-prompt.sh"

  for userfile in $userfiles; do
    if [ -e "$userfile" ]; then
      scp $userfile $address:$HOME/
    fi
  done
}

install_devel()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s $USER
  {
    apt-get -y install \
       build-essential \
       automake autoconf libtool \
       autopoint \
       git
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

