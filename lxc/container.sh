#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

template=busybox
#template=sshd
container=my${template}

dropbear_port=2222
DROPBARE_RSAKEY=/etc/dropbear/dropbear_rsa_host_key
DROPBARE_RSAKEY_ARGS=

rootfs=/var/lib/lxc/$container/rootfs

help()
{
    usage
}

usage()
{
  echo "usage : $0 [options] target1 target2 ..."
  echo ""
  echo "  target"
  echo "    create"
  echo "    start"
  echo "    stop"
  echo "    "
  echo "    clean"
  echo "    mclean"
  exit 0
}

create_key()
{
  echo "create_key"
  rm -f ~/.ssh/id_dropbear
  dropbearkey -t rsa -f ~/.ssh/id_dropbear -s 2048 > ~/.ssh/id_dropbear.txt

  rm -f ~/.ssh/id_rsa.pub
  cat ~/.ssh/id_dropbear.txt | grep -e '^ssh-rsa ' > ~/.ssh/id_rsa.pub
  rm -f ~/.ssh/id_dropbear.txt

  dropbearconvert dropbear openssh ~/.ssh/id_dropbear ~/.ssh/id_rsa

}

copy_key()
{
  echo "copy_key"
  mkdir -p $rootfs/root/.ssh/
  chmod 700 $rootfs/root/.ssh/
  cp -f ~/.ssh/id_rsa.pub $rootfs/root/.ssh/authorized_keys
}

create()
{
  lxc-create -t $template -n $container
  if [ "x$template" = "xbusybox" ]; then
    config=/var/lib/lxc/$container/config

    sed -i.bak -e \
      's|^lxc.network.type = empty|lxc.network.type = none|' \
      $config
    
    # revise errors of 'start'    
    sed -i.bak -e \
      's|^lxc.mount.entry = /dev dev|#lxc.mount.entry = /dev dev|' \
      $config
    sed -i.bak -e \
      's|^lxc.mount.entry = /usr/share/lxc/templates|#lxc.mount.entry = /usr/share/lxc/templates|' \
      $config
    sed -i.bak -e \
      's|^lxc.mount.entry = /etc/init.d |#lxc.mount.entry = /etc/init.d |' \
      $config

    echo 'lxc.mount.entry = /sbin sbin none ro,bind 0 0' >> $config

    cat $config

    cp -f /etc/init.d/dropbear $rootfs/etc/init.d/
    sed -i.bak -e \
      "s|^DROPBEAR_PORT=22|DROPBEAR_PORT=$dropbear_port|" \
      $rootfs/etc/init.d/dropbear
    sed -i.bak -e \
      's|^DROPBEAR_EXTRA_ARGS=|DROPBARE_EXTRA_ARGS="-g -B"|' \
      $rootfs/etc/init.d/dropbear

    # create host key
    #mkdir -p $rootfs/etc/dropbear
    #dropbearkey -t rsa -f $rootfs/$DROPBARE_RSAKEY $DROPBARE_RSAKEY_ARGS > /dev/null

    echo "done"

    create_key
    copy_key
  fi


}

ls()
{
  lxc-ls -f
}

start()
{
  lxc-start -n $container -d -l debug -o ${container}.log
  
  # OK
  lxc-attach -n $container -- /bin/sh -c '/etc/init.d/dropbear start'
  
  # NG
  # lxc-attach -n $container -- /etc/init.d/dropbear start
}

ps()
{
  lxc-attach -n $container -- ps -ef
}

attach()
{
  lxc-attach -n $container -- /bin/sh
}

connect()
{
  ssh -y -y -p 2222 192.168.7.2
}

log()
{
  cat ${container}.log | grep ERROR
}

stop()
{
  lxc-stop -n $container -k
}

destroy()
{
  lxc-destroy -n $container
}

mclean()
{
  :
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
	LANG=C type $target | grep function > /dev/null 2>&1
	res=$?
	if [ "x$res" = "x0" ]; then
		$target
	else
		make $target
	fi
done

