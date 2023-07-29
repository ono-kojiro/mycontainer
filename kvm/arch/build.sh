#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"
cd ${top_dir}
  
disk=`pwd`/archlinux.qcow2
iso=$HOME/Downloads/archlinux-2023.04.01-x86_64.iso

name="archlinux"

disk()
{
  qemu-img create -f qcow2 $disk 16G
}

install()
{
  LANG=C virt-install \
    --name ${name} \
    --os-variant=archlinux \
    --vcpus 2 \
    --ram 4096 \
    --disk=$disk,bus=virtio \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --network bridge=br0 \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty \
    --check all=off \
    --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader_ro=yes,loader_type=pflash
}

dump()
{
  virsh dumpxml $name
}

view()
{
  virt-viewer
}

blk()
{
  virsh domblklist $name --details
}

media()
{
  virsh change-media $name sda $iso
}

mount()
{
  virsh attach-disk $name $iso sda --type cdrom --mode readonly --current
}

hosts()
{
  ansible-inventory -i groups.ini --list --yaml > hosts.yml
}

deploy()
{
  ansible-playbook -i hosts.yml site.yml
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

shutdown()
{
  virsh shutdown $name --mode agent
}

stop()
{
  virsh destroy $name
}

destroy()
{
  virsh destroy $name
}


edit()
{
  virsh edit $name
}


undefine()
{
  virsh undefine --nvram $name
}

all()
{
  :
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
    * )
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  all
  exit
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

