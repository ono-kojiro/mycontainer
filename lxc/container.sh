#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

#template=busybox
template=sshd
container=my${template}

addrs="192.168.8.2 192.168.8.3 192.168.8.4"
port=22

rsa_host_key=/etc/dropbear/dropbear_rsa_host_key
dss_host_key=/etc/dropbear/dropbear_dss_host_key
ecdsa_host_key=/etc/dropbear/dropbear_ecdsa_host_key

bridge="lxcbr0"


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
  echo ""
  echo "    attach"
  echo "    ssh"
  echo "    stop"
  echo ""
  echo "    clean"
  echo "    mclean"
  exit 0
}

list()
{
  items=`lxc-ls -f | grep -v "^NAME" | gawk '{ printf "%s ", $1 }'`

  echo $items
  for item in $items ; do
    echo "item is $item"
  done
}

create()
{
  set -- $addrs
  for addr in "$@"; do
    id=`echo "$addr" | cut -d . -f 4`
    name=my${template}${id}
    rootfs=/var/lib/lxc/$name/rootfs
    echo "create $name, $addr"
    create_container $name $template $addr $rootfs
  done
}

destroy()
{
  items=`lxc-ls -f | grep -v "^NAME" | gawk '{ printf "%s ", $1 }'`
  for item in $items ; do
    lxc-destroy -n "$item"
  done
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
  fi

  cat /etc/network/interfaces | \
    grep lxcbr0 > /dev/null 2>&1
  res=$?

  if [ "x$res" = "x1" ]; then
    setup_bridge
    /etc/init.d/network restart
  fi
}

setup_bridge()
{
  cat - << EOS >> /etc/network/interfaces
auto lxcbr0
iface lxcbr0 inet static
  address 192.168.8.1
  netmask 255.255.255.0
  broadcast 192.168.8.255
  gateway 192.168.8.1
EOS

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
  rootfs=$1
  echo "copy_key"

  # dummy
  mkdir -p $rootfs/home/root

  mkdir -p $rootfs/root/.ssh/
  chmod 700 $rootfs/root/.ssh/
  src=~/.ssh/id_rsa.pub
  dst=$rootfs/root/.ssh/authorized_keys
  echo "cp -f $src $dst"
  cp -f $src $dst
}

create_container()
{
  container=$1
  template=$2
  addr=$3
  rootfs=$4

  echo "lxc-create -t $template -n $container"
  lxc-create -t $template -n $container
  config=/var/lib/lxc/$container/config

  ### common
  sed -i.bak -e \
    's|^lxc.network.type = empty|lxc.network.type = veth|' \
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

  echo "" >> $config
  echo "lxc.network.link = lxcbr0" >> $config
  echo "lxc.network.flags = up" >> $config
  echo "lxc.network.ipv4.address = $addr" >> $config

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
    dropbearkey -t rsa   -f ${rootfs}${rsa_host_key} > /dev/null
    dropbearkey -t dss   -f ${rootfs}${dss_host_key} > /dev/null
    dropbearkey -t ecdsa -f ${rootfs}${ecdsa_host_key} > /dev/null
 
    # solve the error "user 'root' has invalid shell, rejected"
    cp -f /etc/shells $rootfs/etc/

  fi
  
  echo "done"

  create_key
  copy_key $rootfs
}

ls()
{
  lxc-ls -f
}

start()
{
  items=`lxc-ls -f | grep -v "^NAME" | gawk '{ printf "%s ", $1 }'`
  for item in $items ; do
    echo -n "start $item ..."
    lxc-start -n "$item" -l debug -o ${item}.log
    echo "done"
  done
  
  #lxc-autostart
}

restart()
{
  stop
  start
}

wait()
{
  sleep 1s
}

ps()
{
  items=`lxc-ls -f | grep -v "^NAME" | gawk '{ printf "%s ", $1 }'`
  for item in $items ; do
    echo "CONTAINER : $item"
    lxc-attach -n "$item" -- ps -ef
  done
}

check()
{
  stop
  destroy
  create
  ls
  start
  sleep 3s
  test
}

test()
{
  ok=0
  ng=0

  set -- $addrs
  for addr in "$@"; do
    id=`echo "$addr" | cut -d . -f 4`
    name=my${template}${id}
    rootfs=/var/lib/lxc/$name/rootfs
    echo "debug, $addr, $name, $rootfs"
    command ssh -y -y $addr ps -ef | grep dropbear
    res=$?
    if [ "$res" = "0" ]; then
      let "ok=ok+1"
    else
      let "ng=ng+1"
    fi
  done

  if [ "$ok" != "0" ]; then
    if [ "$ng" = "0" ]; then
      echo "Passed (ok = $ok, ng = $ng)"
    else
      echo "Failed (ok = $ok, ng = $ng)"
    fi
  else
    echo "Failed (ok = $ok, ng = $ng)"
  fi

}

stop()
{
  lxc-autostart -k
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

create_bridge ${bridge}

for target in "$@" ; do
	LANG=C type $target 2>&1 | grep function > /dev/null 2>&1
	res=$?
	if [ "x$res" = "x0" ]; then
		$target
	else
		echo "no such target, '$target'"
		break
	fi
done

