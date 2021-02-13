#!/bin/sh


top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

#template=busybox
template=sshd
container=my${template}

address=192.168.7.2
#address=192.168.8.2

if [ "x$template" = "xbusybox" ]; then
  port=10022
elif [ "x$template" = "xsshd" ]; then
  port=20022
else
  echo "invalid template, $template"
  exit 1
fi

DROPBEAR_RSAKEY=/etc/dropbear/dropbear_rsa_host_key
DROPBEAR_RSAKEY_ARGS=

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

clear_key()
{
  rm -f ~/.ssh/id_dropbear
  rm -f ~/.ssh/id_rsa.pub
  rm -f ~/.ssh/id_dropbear.txt
  rm -f ~/.ssh/id_rsa
}

create_bridge()
{
  brctl show | grep lxcbr0 > /dev/null 2>&1
  res=$?
  if [ "x$res" = "x1" ]; then
    brctl addbr lxcbr0
  else
    echo lxcbr0 already exists.
  fi 
}

create_key()
{
  if [ ! -e ~/.ssh/id_dropbear ]; then
    echo "create_key"
    dropbearkey -t rsa -f ~/.ssh/id_dropbear -s 2048 > ~/.ssh/id_dropbear.txt
    cat ~/.ssh/id_dropbear.txt | grep -e '^ssh-rsa ' > ~/.ssh/id_rsa.pub
    rm -f ~/.ssh/id_dropbear.txt
  fi

  if [ ! -e ~/.ssh/id_rsa ]; then
    dropbearconvert dropbear openssh ~/.ssh/id_dropbear ~/.ssh/id_rsa
  fi
}

copy_key()
{
  echo "copy_key"

  # dummy
  mkdir -p $rootfs/home/root

  mkdir -p $rootfs/root/.ssh/
  chmod 700 $rootfs/root/.ssh/
  cp -f ~/.ssh/id_rsa.pub $rootfs/root/.ssh/authorized_keys
}

create()
{
  lxc-create -t $template -n $container
  config=/var/lib/lxc/$container/config

  ### common
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

  if [ "x$template" = "xbusybox" ]; then
    echo 'lxc.mount.entry = /usr/bin  usr/bin  none ro,bind 0 0' \
      >> $config
    echo 'lxc.mount.entry = /sbin sbin none ro,bind 0 0' \
      >> $config

    #cat $config
  fi

  echo '' >> $config
  echo 'lxc.start.auto = 1' >> $config
  

  cp -f /etc/init.d/dropbear $rootfs/etc/init.d/
  sed -i.bak -e \
    "s|^DROPBEAR_PORT=22|DROPBEAR_PORT=$port|" \
    $rootfs/etc/init.d/dropbear
  sed -i.bak -e \
    's|^DROPBEAR_EXTRA_ARGS=|DROPBEAR_EXTRA_ARGS=" -B"|' \
    $rootfs/etc/init.d/dropbear

  mkdir -p $rootfs/etc/rc2.d/
  cd $rootfs/etc/rc2.d/
  ln -s ../init.d/dropbear S01dropbear
  cd $top_dir

  #echo "/etc/init.d/dropbear start" \
  #  >> $rootfs/etc/init.d/rcS

  if [ "x$template" = "xsshd" ]; then
    # create host key
    mkdir -p $rootfs/etc/dropbear
    dropbearkey -t rsa \
      -f $rootfs/$DROPBEAR_RSAKEY \
      $DROPBEAR_RSAKEY_ARGS > /dev/null

    dropbearkey -t dss \
      -f $rootfs/etc/dropbear/dropbear_dss_host_key
    dropbearkey -t ecdsa \
      -f $rootfs/etc/dropbear/dropbear_ecdsa_host_key

    # solve the error "user 'root' has invalid shell, rejected"
    cp -f /etc/shells $rootfs/etc/

  fi
  
  echo "done"

  create_key
  copy_key
}

ls()
{
  lxc-ls -f
}

start()
{
  rm -f ${container}.log
  lxc-start -n $container -d -l debug -o ${container}.log

  sleep 1s
  start_service
}

execute()
{
  lxc-execute -n $container -- /etc/init.d/dropbear start &
  sleep 1s
}

start_service()
{
  # NG
  lxc-attach -n $container -l debug -o attach.log -- /bin/sh -c '/etc/init.d/dropbear start; exit'
  :  
  # NG
  # lxc-attach -n $container -- /etc/init.d/dropbear start
}

wait()
{
  sleep 1s
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
  # call ssh command instead of function 'ssh'
  command ssh -y -y -p $port $address ps -ef
}

ssh()
{
  # call ssh command instead of function 'ssh'
  command ssh -y -y -p $port $address
}

test()
{
  stop
  destroy
  create
  ls
  start
  sleep 3s
  connect
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

clean()
{
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
	LANG=C type $target | grep function > /dev/null 2>&1
	res=$?
	if [ "x$res" = "x0" ]; then
		$target
	else
		make $target
	fi
done

