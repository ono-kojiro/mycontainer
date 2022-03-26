#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="focal"

template="download"

dist="ubuntu"
release="$name"
arch="amd64"

rootfs="$HOME/.local/share/lxc/$name/rootfs"

help()
{
  usage
}

usage()
{
	echo "usage : $0 [options] target1 target2 ..."
    echo ""
    echo "  target:"
    echo "    create"
    echo "    init"
    echo "    start"
    echo "    update"
    echo "    attach"
    echo "    stop"
    echo "    destroy"
}

all()
{
  config
  build
}

create()
{
  lxc-create -t download -n $name -- -d $dist -r $release -a $arch
}

init()
{
  cp -f ./config      $HOME/.local/share/lxc/$name/
  cp -f ./10-lxc.yaml $rootfs/etc/netplan/
}

start()
{
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  lxc-start -n $name
}

update()
{
  cp -f ./10-lxc.yaml $rootfs/tmp/
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    cp -f /tmp/10-lxc.yaml /etc/netplan/

    apt -y update
    apt -y upgrade
  }
EOS

}

upgrade()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    apt -y update
    apt -y upgrade

  }
EOS

}

enable_sshd()
{
  cat - << 'EOS' | lxc-attach -n $name --clear-env -- /bin/bash -s
  {
    apt -y install openssh-server
  }
EOS

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

clean()
{
	rm -f ${container}.log
	stop
	destroy
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

