#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

name=netbsd
disk=`pwd`/${name}.qcow2
iso="$HOME/Downloads/NetBSD-9.3-amd64.iso"

addr="192.168.10.105"

inventory="hosts"
playbook="site.yml"

ansible_opts=""
ansible_opts="$ansible_opts -i ${inventory}"

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

disk()
{
  if [ ! -e $disk ]; then
    qemu-img create -f qcow2 $disk 16G
  fi
}


install()
{
  virt-install \
    --name ${name} \
    --ram 4096 \
    --disk=$disk,bus=virtio \
    --vcpus 4 \
    --os-variant netbsd9.0 \
    --network bridge=br0 \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty

#  --extra-args 'console=ttyS0,115200n8 serial'
#   --network network=default --noautoconsole \
}


key()
{
  ssh-keygen -t ed25519 -N '' -f ./id_ed25519 -C netbsd
}

connect()
{
  command ssh root@${addr}
}

ssh()
{
  command ssh root@${addr} -i ./id_ed25519
}

sftp()
{
  command sftp -i id_ed25519 root@${addr}
}

install_python()
{
  command ssh root@${addr} -i id_ed25519 -- pkg install -y python
}

hosts()
{
  ansible-inventory -i groups.ini --list --yaml > hosts.yml
}

deploy()
{
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
  virsh destroy $name
}


undefine()
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

