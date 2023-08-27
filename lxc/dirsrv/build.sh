#!/bin/sh

# Please modify apparmor configuration in LXC host.
#
# https://github.com/systemd/systemd/issues/17866#issuecomment-1445271032
#

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="rocky9"

template="download"

dist="rockylinux"
release="9"
arch="amd64"

#address="10.0.3.6${release}"
address="192.168.10.69"
gateway="192.168.10.1"
nameserver="192.168.0.1"

rootfs="$HOME/.local/share/lxc/$name/rootfs"
  
seckey="id_ed25519"
pubkey="id_ed25519.pub"

link_dev="br0"

ssh_opts=""
ssh_opts="$ssh_opts -o UserKnownHostsFile=/dev/null"
ssh_opts="$ssh_opts -o StrictHostKeyChecking=no"

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
    echo ""
    echo "  target:"
    echo "    create/init/start"
    echo "    chpasswd/copy_files"
    echo "    permit_root_login/enable_pubkey/test_ssh"
    echo "    attach"
    echo "    stop"
    echo "    destroy"
}

all()
{
  create

  # configure using lxc-execute command
  enable_static
  set_nameserver
  #copy_files
  chpasswd
  send_pubkey

  start
 
  install_sshd 
  permit_root_login
  test_ssh

  #enable_sssd
  #test_sssd

  #mkhomedir

  #copy_pubkey
  #post_proc
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

security.nesting = true
lxc.include = /usr/share/lxc/config/nesting.conf
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
}

start()
{
  echo "INFO : start"
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  lxc-start -n $name
  
  sleep 1
  lxc-attach -n $name -- nmcli con up eth0
}

attach()
{
  lxc-attach -n $name --clear-env -- /bin/bash
}

set_nameserver()
{
  cat - << EOF | lxc-execute -n $name -- \
    /bin/bash -c 'tee /etc/resolv.conf'
nameserver $nameserver
EOF
}

copy_files()
{
  cat - << EOF | lxc-execute -n $name -- /bin/bash -c 'tee /enable_eth0.sh'
#!/bin/sh
ip link set eth0 up
ip route replace default via $gateway
echo "nameserver $nameserver" > /etc/resolv.conf
EOF

  lxc-execute -n $name -- /bin/bash -c 'chmod 755 /enable_eth0.sh'
  
  cat - << EOF | lxc-execute -n $name -- \
    /bin/bash -c 'tee /etc/systemd/system/myservice.service'
[Unit]
Description=myservice
After=systemd-journald.service

[Service]
ExecStartPre=/bin/sleep 3
ExecStart=/enable_eth0.sh

[Install]
WantedBy=multi-user.target
EOF

  #lxc-execute -n $name -- /bin/bash -c 'systemctl enable myservice'
  
}

chpasswd()
{
  echo "INFO : chpasswd"
  lxc-execute -n $name -- /bin/bash -c 'echo "root:secret" | /usr/sbin/chpasswd'
}

down()
{
  destroy
}

install_sshd()
{
  echo "INFO : install sshd"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    dnf -y update
    dnf -y install openssh-server
  }
EOS

}


permit_root_login()
{
  echo "INFO : permit_root_login"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
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

install_devtools()
{
  echo "INFO : install_devtools"
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    dnf -y groupinstall "Development Tools"
    dnf -y install which
  }
EOS

}

send_pubkey()
{
  cat - << EOF | lxc-execute -n $name -- /bin/bash -s
{
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
}
EOF

  cat $HOME/.ssh/id_ed25519.pub | lxc-execute -n $name -- tee /root/.ssh/authorized_keys
}

keygen()
{
  enable_pubkey
}

test_ssh()
{
  command ssh -y $ssh_opts root@$address ip addr
}

connect()
{
  command ssh -y $ssh_opts root@$address
}

ssh()
{
  connect
}

enable_sssd()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s
  {
    dnf -y install sssd sssd-tools sssd-ldap authselect oddjob-mkhomedir
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
    chmod 600 /etc/sssd/sssd.conf
    systemctl restart sssd

    authselect select sssd with-sudo with-mkhomedir --force
    systemctl enable --now oddjobd.service
  }
EOS

}

test_sssd()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s $USER
  {
    user=$1
    id $user

    gpasswd -a $user wheel
  }
EOS

}

mkhomedir()
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
}

copy_pubkey()
{
  cat - << 'EOS' | ssh $ssh_opts root@$address /bin/bash -s $USER
  {
    user=$1
    mkdir -p              /home/$user/.ssh
    chown $user:ldapusers /home/$user/.ssh
    chmod 700             /home/$user/.ssh
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

post_proc()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    systemctl enable myservice.service
  }
EOS

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

mclean()
{
  lxc-stop -n $name -k || true
  lxc-destroy -n $name || true
}

deploy()
{
  ansible-playbook -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook -i hosts.yml -t $tag site.yml
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
  all
fi

for arg in $args; do
  LANG=C type $arg | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

