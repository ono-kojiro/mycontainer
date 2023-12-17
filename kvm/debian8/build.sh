#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"
cd $top_dir

name=debian8
disk=`pwd`/${name}.qcow2
disk_size="16G"
iso="$HOME/Downloads/OS/debian-8.11.1-amd64-DVD-1.iso"
br="br60"

all()
{
  usage
}

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

osinfo()
{
  osinfo-query os
}

disk()
{
  if [ ! -e "$disk" ]; then
    qemu-img create -f qcow2 $disk $disk_size
  fi
}

install()
{
  disk

  virt-install \
    --name $name \
    --ram 1024 \
    --disk=$disk,bus=virtio \
    --vcpus 1 \
    --os-variant debian8 \
    --console pty,target_type=serial \
    --network bridge=$br \
    --location=$iso \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty 
  
#  --extra-args 'console=tty0 ttyS0,115200n8'
    
}

help()
{
  usage
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
  virsh destroy  $name
  virsh undefine $name
}

list()
{
  virsh list --all
}

status()
{
  list
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
  playbook=$1
  ansible-playbook ${ansible_opts} -i hosts.yml ${playbook}
}

vnc()
{
  virt-viewer
}

install_python()
{
  addr=`cat hosts.yml | grep ansible_host | gawk '{ print $2 }'`
  user=`cat hosts.yml | grep ansible_user | gawk '{ print $2 }'`
  ssh -l $user $addr apk add python3
}

deploy()
{
  ansible-playbook -i hosts.yml apt.yml
}

#hosts

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
    -p | --playbook)
      shift
      playbook=$1
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
    default $target
    #echo "ERROR : $target is not a shell function"
    #exit 1
    #ansible-playbook ${ansible_opts} -i hosts -t ${target} site.yml
  fi
done

