#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="bionic"

template="download"

dist="ubuntu"
release="$name"
arch="amd64"

address="10.0.3.184"
gateway="10.0.3.1"

rootfs="$HOME/.local/share/lxc/$name/rootfs"
  
seckey="id_ed25519"
pubkey="id_ed25519.pub"

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
  setup_user_config
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

attach()
{
  lxc-attach -n $name --clear-env -- /bin/bash
}

config_network()
{
  echo "INFO : config_network"

  cat - << EOS > temp.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp-identifier: mac
      addresses: [$address/24]
      gateway4: $gateway
      nameservers:
        addresses: [ $gateway ]
EOS

  cat temp.yaml | lxc-attach -n $name -- tee /etc/netplan/10-lxc.yaml
  
  # avoid following error. 
  #
  #  subprocess.CalledProcessError:
  #  Command '['systemctl', 'stop', '--no-block', 'systemd-networkd.service',
  #   'netplan-wpa-*.service']' returned non-zero exit status 1.                                                   
  echo "INFO : sleep 1sec"
  sleep 1s

  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    netplan apply
  }
EOS

  rm -f temp.yaml

}

update()
{
  echo "INFO : update"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    export DEBIAN_FRONTEND=noninteractive

    perl -p -i.bak -e 's%(deb(?:-src|)\s+)https?://(?!archive\.canonical\.com|security\.ubuntu\.com)[^\s]+%$1http://jp.archive.ubuntu.com/ubuntu/%' /etc/apt/sources.list 
    
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

  cat $HOME/.ssh/id_ed25519.pub | lxc-attach -n $name -- tee $HOME/.ssh/authorized_keys

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
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    echo "ERROR : $arg is not shell function"
    exit 1
  fi
done

