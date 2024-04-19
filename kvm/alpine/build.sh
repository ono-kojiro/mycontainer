#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"
cd $top_dir

name=alpine
disk=`pwd`/${name}.qcow2
iso="$HOME/Downloads/OS/alpine-virt-3.18.4-x86_64.iso"
#iso="$HOME/Downloads/OS/alpine-extended-3.18.4-x86_64.iso"

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

disk()
{
  if [ ! -e "$disk" ]; then
    qemu-img create -f qcow2 $disk 4G
  fi
}

install()
{
  disk

  virt-install \
    --name $name \
    --ram 512 \
    --disk=$disk,bus=virtio \
    --vcpus 1 \
    --os-variant alpinelinux3.18 \
    --console pty,target_type=serial \
    --network bridge=br1 \
    --location=$iso \
    --nographics \
    --serial pty

#    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
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
  playbook=$1
  ansible-playbook ${ansible_opts} -i hosts.yml ${playbook}.yml
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
  ansible-playbook -i hosts.yml site.yml
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

