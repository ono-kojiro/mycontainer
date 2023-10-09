#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

# https://wiki.freebsd.org/KubilayKocak/SystemSecurityServicesDaemon

name=ghostbsd
disk=`pwd`/${name}.qcow2
iso="$HOME/Downloads/GhostBSD-23.06.01.iso"

usage()
{
  cat - << EOF
usage : $0 target1 target2 ...

target
  all
  usage

  disk
  install

  status

  (after enabling pubkey auth...)
  install_python
  deploy

  stop
  destroy

  escape character is ^] (Ctrl + ])
EOF
}

help()
{
  usage
}

prepare()
{
  ansible-galaxy collection install community.general
}

disk()
{
  qemu-img create -f qcow2 $disk 32G
}

install()
{
  virt-install \
    --name ${name} \
    --ram 4096 \
    --disk=$disk,bus=virtio \
    --vcpus 4 \
    --os-variant freebsd13.0 \
    --network bridge=br0 \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --input tablet,bus=usb \
    --input keyboard,bus=usb \
    --input mouse,bus=usb \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty \
    --print-xml

#  --extra-args 'console=ttyS0,115200n8 serial'
}


deploy()
{
  # install python311 by hand
  ansible-playbook -i hosts.yml site.yml
}

shutdown()
{
  virsh shutdown $name
}

dumpxml()
{
  virsh dumpxml $name
}

dominfo()
{
  virsh dominfo $name
}

stop()
{
  shutdown
}

destroy()
{
  virsh undefine $name
}

all()
{
  usage
}

list()
{
  virsh list --all
}

status()
{
  list
}

osinfo()
{
  osinfo-query os
}

start()
{
  virsh start $name
}

console()
{
  virsh console $name
}

hosts()
{
  ansible-inventory -i groups.yml --list --yaml > hosts.yml
}


while [ $# -ne 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  all
fi

for target in "$@"; do
  LANG=C type "$target" | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo "ERROR : $target is not a shell function"
    exit 1
  fi
done

