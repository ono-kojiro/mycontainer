#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="bullseye"

template="download"

dist="debian"
release="$name"
arch="amd64"

address="192.168.10.101"
gateway="192.168.10.1"

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
  cat << EOS
usage : $0 [options] target1 target2 ...

target:
  create
  start
  change_source_list
  config_network
  apt_update
  set_locale
  chpasswd
  enable_sshd
  enable_pubkey_auth
  test_ssh
EOS

}

all()
{
  create
  start
  initialize
  change_source_list
  config_network
  apt_update
  set_locale
  chpasswd
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
  config
}

config()
{
  config="$HOME/.local/share/lxc/$name/config"

  cat - << EOS >> $config

lxc.net.0.ipv4.address = $address/24
lxc.net.0.ipv4.gateway = $gateway

lxc.cgroup.devices.allow =
lxc.cgroup.devices.deny =
 
EOS

  # change link device
  sed -i -e 's|lxc.net.0.link = lxcbr0|lxc.net.0.link = br0|' $config
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

initialize()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    rm -f /etc/resolv.conf
    echo "nameserver 8.8.8.8" | tee /etc/resolv.conf
  }
EOS

}

init()
{
  initialize
}

change_source_list()
{
  cat - << 'EOS' | lxc-attach -n $name -- tee /etc/apt/sources.list
    deb http://ftp.jaist.ac.jp/debian bullseye main
    deb http://ftp.jaist.ac.jp/debian bullseye-updates main
    deb http://security.debian.org/debian-security/ bullseye-security main
EOS
}

set_locale()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    apt-get -y install locales
    sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen
    locale-gen
    update-locale LANG=ja_JP.UTF-8
  }
EOS

}

test_attach()
{
  lxc-attach -n $name
}

config_network()
{
  echo "INFO : config_network"

  cat - << EOS | lxc-attach -n $name --clear-env -- /bin/bash -s
{
  echo "address is $address"
  echo "gateway is $gateway"
  echo "nameserver 8.8.8.8" | tee /etc/resolv.conf
}
EOS

}

apt_update()
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
  
    # https://lowendtalk.com/discussion/175668/takes-minutes-to-login-to-hostcram
    systemctl mask systemd-logind
  }
EOS

}

enable_pubkey_auth()
{
  rm -f $pubkey $seckey
  
  cat - << EOS | lxc-attach -n $name --clear-env -- /bin/bash -s
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
  command ssh -y $ssh_opts root@$address ip addr
}

ssh()
{
  cmd="ssh -y $ssh_opts root@$address -vvv"
  echo $cmd
  command $cmd
}

enable_sssd()
{
  cat - << EOS | ssh $ssh_opts root@$address /bin/bash -s
  {
    apt-get -y install sssd-ldap oddjob-mkhomedir apt-utils
  }
EOS

  ldap_suffix="dc=example,dc=com"
  ldap_url="ldap://192.168.10.1"

  cat - << EOS | lxc-attach -n $name -- tee /etc/sssd/sssd.conf
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

ldap_uri = $ldap_url
ldap_search_base = $ldap_suffix

ldap_chpass_uri = $ldap_url

ldap_id_use_start_tls = true
ldap_tls_reqcert = never

ldap_user_search_base  = ou=Users,$ldap_suffix
ldap_group_search_base = ou=Groups,$ldap_suffix

access_provider = simple
simple_allow_groups = ldapusers

enumerate = true
EOS

  cat - << EOS | ssh $ssh_opts root@$address /bin/bash -s
  {
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

if [ -z "$args" ]; then
  usage
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

