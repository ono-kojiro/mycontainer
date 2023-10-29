#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

name="alma9"
disk=${top_dir}/${name}.qcow2
iso="$HOME/Downloads/OS/AlmaLinux-9.2-x86_64-minimal.iso"

usage()
{
  cat - << EOF
usage : $0 target1 target2 ...

target
  all
  usage

  disk
  install
  escape character is ^] (Ctrl + ])
EOF
}

help()
{
  usage
}

disk()
{
  if [ ! -e $disk ]; then
    qemu-img create -f qcow2 $disk 16G
  fi
}


install()
{
  disk

  virt-install \
    --name $name \
    --ram 4096 \
    --disk=$disk,bus=virtio \
    --vcpus 2 \
    --network bridge=br0 \
    --network network=ovs-network \
    --os-variant centos-stream9 \
    --graphics none \
    --console pty,target_type=serial \
    --location=$iso \
    --extra-args 'console=ttyS0,115200n8 serial'
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
  virsh destroy $name
}

down()
{
  destroy
}

undefine()
{
  virsh undefine $name
}

delete()
{
  undefine
}

all()
{
  usage
}

list()
{
  virsh list --all
}

netlist()
{
  virsh net-list
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

default()
{
  tag=$1
  ansible-playbook ${ansible_opts} -t ${tag} site.yml
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
    #exit 1
    default $target
  fi
done

