#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

name="omnios"

disk=`pwd`/omnios.qcow2

all()
{
  :
}

install()
{
  qemu-img create -f qcow2 $disk 16G

  #iso=/home/$USER/Downloads/omnios-r151042.iso
  #iso=/media/$USER/SSD512GB/Downloads/OS/Unix/omnios-r151042.iso
  iso=$HOME/Downloads/omnios-r151042.iso

  virt-install \
    --name $name \
    --ram 4096 \
    --disk=$disk,bus=virtio \
    --vcpus 4 \
    --os-variant solaris11 \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty \
    --network bridge=br0

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

destroy()
{
  virsh destroy $name
}

undefine()
{
  virsh undefine $name
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
  fi
done

