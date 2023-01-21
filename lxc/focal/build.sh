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
  echo "usage : $0 [options] target1 target2 ..."
cat - << EOS
  target:
    create/init/start
    chpasswd
    enable_sshd
    update
    attach
    stop
    destroy
EOS
}

all()
{
  create
  init
  start
  chpasswd
  config_proxy
  config_network
  update
  enable_sshd
  enable_pubkey_auth
  test_ssh

  #enable_sssd
  #test_sssd

  #setup_default_user
  #setup_user_config
}

create()
{
  opts=""
  if [ -n "$http_proxy" ] || [ -n "$https_proxy" ] || [ -n "$ftp_proxy" ]; then
    opts="$opts --no-validate"
  fi

  lxc-create -t download -n $name -- -d $dist -r $release -a $arch $opts
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

bash()
{
  lxc-attach -n $name --clear-env -- /bin/bash
}

config_proxy()
{
  rm -f ./apt.conf
  touch ./apt.conf

  if [ -n "$http_proxy" ]; then
    cat - << EOS >> apt.conf
Acquire::http::Proxy "$http_proxy";
EOS
  fi
  
  if [ -n "$https_proxy" ]; then
    cat - << EOS >> apt.conf
Acquire::https::Proxy "$https_proxy";
EOS
  fi

  cat apt.conf | lxc-attach -n $name --clear-env -- \
    tee /etc/apt/apt.conf
  
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    chmod 644 /etc/apt/apt.conf
  }
EOS

  rm -f apt.conf

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
    netplan set ethernets.eth0.gateway4=$gateway
    netplan set ethernets.eth0.nameservers.addresses=[8.8.8.8]

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

  cat - << 'EOS' > sssd.conf
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
  
  scp $ssh_opts \
    ./sssd.conf root@$address:/etc/sssd/sssd.conf
  rm -f ./sssd.conf
 
  # change permission and start sssd
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
  lxc-stop    -n $name || true
  lxc-destroy -n $name || true
}

clean()
{
  destroy
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
  lxc-attach -n $container -- /bin/bash
}

mclean()
{
  lxc-stop -n $name -k || true
  lxc-destroy -n $name || true
  rm -rf ./id_ed25519
  rm -rf ./id_ed25519.pub
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

if [ "x$args" = "x" ]; then
  all
fi

for arg in $args; do
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    echo "ERROR : $arg is not shell function"
    exit 1
  fi
done

