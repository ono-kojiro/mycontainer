#!/bin/sh

set -e

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="arch"

template="download"

dist="archlinux"
release="current"
arch="amd64"

address="10.0.3.67"

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
  chpasswd

  #copy_files

  #network
  dns
  #gw
  #up
  #update
  update
  
  enable_myservice
  
  enable_sshd
  enable_pubkey
  #test_ssh

  enable_sssd
  #test_sssd

  mkhomedir

  copy_pubkey

  update_nss
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

copy_files()
{
  cat enable_eth0.sh    | lxc-attach -n $name -- tee /enable_eth0.sh
  cat myservice.service | lxc-attach -n $name -- tee /etc/systemd/system/myservice.service

  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    chmod 755 /enable_eth0.sh
  }
EOS
}

update()
{
  echo "INFO : update"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    pacman -Syu --noconfirm
  }
EOS

}

attach()
{
  lxc-attach -n $name --clear-env /bin/bash
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

network()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s $gateway
  {
    gateway=$1
    echo "replace default gateway $gateway"
    ip route replace default via $gateway
  }
EOS
  
}

dns()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s $gateway
  {
    echo "set nameserver"
    rm -rf /etc/resolv.conf
    echo 'nameserver 10.0.3.1' > /etc/resolv.conf
    cat /etc/resolv.conf
  }
EOS
}


gw()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s $gateway
  {
    gateway=$1
    echo "change default gateway $gateway"
    echo ip route replace default via $gateway
    ip route replace default via $gateway
  }
EOS
}

up()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s $gateway
  {
    echo "ip link set eth0 up"
    ip link set eth0 up
    ip addr show eth0
  }
EOS
}

down()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s $gateway
  {
    ip link set eth0 down
  }
EOS
}

enable_sshd()
{
  echo "INFO : enable_sshd"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    pacman -S --needed --noconfirm openssh
    
    sed -i \
      's|#PermitRootLogin prohibit-password|PermitRootLogin yes|' \
      /etc/ssh/sshd_config
    
    sed -i \
      's|#PasswordAuthentication yes|PasswordAuthentication yes|' \
      /etc/ssh/sshd_config

    systemctl restart sshd
  }
EOS

}

enable_pubkey()
{
  rm -f ./id_ed25519*
  
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
  enable_pubkey
}

test_ssh()
{
  ssh -y $ssh_opts root@$address ip addr
}

enable_sssd()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    pacman -S --needed --noconfirm sssd
  }
EOS
  
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    rm -f /etc/sssd/sssd.conf
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
  
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    chmod 600 /etc/sssd/sssd.conf
    systemctl restart sssd
  }
EOS

}

update_nss()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    rm -f /tmp/nsswitch.conf
    rm -f /tmp/system-auth
  }
EOS

  cat ./nsswitch.conf | lxc-attach -n $name -- tee /tmp/nsswitch.conf
  cat ./system-auth   | lxc-attach -n $name -- tee /tmp/system-auth

  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    if [ ! -e "/etc/nsswitch.conf.orig" ]; then
      cp -f /etc/nsswitch.conf /etc/nsswitch.conf.orig
    fi
    cp -f /tmp/nsswitch.conf /etc/nsswitch.conf
    cp -f /tmp/system-auth   /etc/pam.d/system-auth
  }
EOS

}

test_sssd()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    user=$1
    id $user

    gpasswd -a $user wheel
  }
EOS

}

mkhomedir()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s $USER
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
}

copy_pubkey()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    user=$1
    mkdir -p              /home/$user/.ssh
    chown $user:ldapusers /home/$user/.ssh
    chmod 700             /home/$user/.ssh
  }
EOS

  cat $HOME/.ssh/id_ed25519.pub | lxc-attach -n $name -- tee $HOME/.ssh/authorized_keys

  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    user=$1
    chmod 755 /home/$user/.ssh/authorized_keys
  }
EOS
}

enable_myservice()
{
  cat myservice \
    | lxc-attach -n $name -- tee /myservice
  
  cat myservice.service \
    | lxc-attach -n $name -- tee /etc/systemd/system/myservice.service

  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    chmod 755 /myservice
    systemctl restart myservice
    systemctl enable myservice.service
  }
EOS

}

enable_logind()
{
  cat systemd-logind.service \
    | lxc-attach -n $name -- tee /tmp/systemd-logind.service

  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    src="/lib/systemd/system/systemd-logind.service"
    dst="/lib/systemd/system/systemd-logind.service.orig"
    if [ ! -e "$dst" ]; then
      cp -f $src $dst
      cp -f /tmp/systemd-logind.service $src
    fi
    systemctl daemon-reload
    systemctl restart systemd-logind
    systemctl enable  systemd-logind
  }
EOS
}


stop()
{
  lxc-stop -n $name
}

status()
{
  #lxc-ls -f
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s $gateway
  {
    ip addr show eth0
  }
EOS
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

console()
{
  lxc-console -n $container
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

