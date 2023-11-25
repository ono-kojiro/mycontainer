#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

name="omnios"
iso=$HOME/Downloads/OS/omnios-r151046.iso

disk=`pwd`/omnios.qcow2

all()
{
  :
}

help()
{
  cat - << EOF
usage: sh build.sh <target>

  target
  - disk
  - install
EOF
}

disk()
{
  if [ ! -e "$disk" ]; then
    qemu-img create -f qcow2 $disk 16G
  fi
}

install()
{
  disk

  virt-install \
    --name $name \
    --ram 2048 \
    --disk=$disk,bus=virtio \
    --vcpus 2 \
    --os-variant solaris11 \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty \
    --network bridge=br1 \
    --autostart \
    --noreboot

    #--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    #--extra-args 'console=ttyS0,115200n8 serial'
}

console()
{
  virsh console $name
}


list()
{
  virsh list --all
}

start()
{
  virsh start $name
}

status()
{
  list
}

shutdown()
{
  virsh shutdown $name
}

stop()
{
  shutdown
}

down()
{
  destroy
  undefine
}

destroy()
{
  virsh destroy $name
}

undefine()
{
  virsh undefine --nvram $name
}

deploy()
{
  ansible-playbook -i hosts.yml -t ldapclient site.yml
  ansible-playbook -i hosts.yml -t sudo       site.yml
}

default()
{
  tag=$1
  ansible-playbook -i hosts.yml -t "$tag" site.yml
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
    #echo "ERROR : $target is not a shell function"
    default $target
  fi
done

