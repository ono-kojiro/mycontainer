#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

disk=/var/lib/libvirt/images/ArchLinux-UEFI.qcow2
iso=/var/lib/libvirt/iso/archlinux-2026.07.01-x86_64.iso

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

  target:
    deply
    reset
EOS

}

all()
{
  deploy
}

clean()
{
  ansible-playbook -i hosts.yml clean.yml
}

hosts()
{
  ansible-inventory -i inventory.yml --list --yaml > hosts.yml
}

create()
{
  sudo qemu-img create -f qcow2 $disk 32G

  sudo virt-install \
  --name ArchLinux-UEFI \
  --memory 4096 \
  --vcpus 2 \
  --disk=$disk,bus=virtio \
  --cdrom=$iso \
  --os-variant archlinux \
  --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader.readonly=yes,loader.type=pflash,nvram=/var/lib/libvirt/qemu/nvram/ArchLinux_VARS_4M.fd \
  --graphics vnc \
  --serial pty
}

install()
{
  ansible-playbook $flags -i hosts.yml -t install site.yml
}

deploy()
{
  ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t ${tag} site.yml
}

hosts

args=""
while [ "$#" -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
    -* )
      flags="$flags $1"
      ;;
    * )
      args="$args $1"
      ;;
  esac
  
  shift
done

if [ -z "$args" ]; then
  help
  exit 1
fi

for arg in $args; do
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

