#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

name="bionic"

template="download"

dist="ubuntu"
release="bionic"
arch="amd64"

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
    echo "    start"
    echo "    attach"
    echo "    stop"
    echo "    destroy"
	exit 0
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
  cp -f ./config      $HOME/.local/share/lxc/bionic/
}

start()
{
  chmod 755 $HOME/.local
  chmod 755 $HOME/.local/share
  lxc-start -n $name
}

update()
{
  cp -f ./10-lxc.yaml $HOME/.local/share/lxc/bionic/rootfs/tmp/
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
  cp -f ./sssd.conf $HOME/.local/share/lxc/bionic/rootfs/tmp/
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

logfile=""

while getopts hvl: option
do
	case "$option" in
		h)
			usage;;
		v)
			verbose=1;;
		l)
			logfile=$OPTARG;;
		*)
			echo unknown option "$option";;
	esac
done

shift $(($OPTIND-1))

if [ "x$logfile" != "x" ]; then
	echo logfile is $logfile
fi

for target in "$@ $TARGETS" ; do
	LANG=C type $target | grep 'function' > /dev/null 2>&1
	res=$?
	if [ "x$res" = "x0" ]; then
		$target
	else
		echo "ERROR : $target is not shell function"
	fi
done
