#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

# https://wiki.freebsd.org/KubilayKocak/SystemSecurityServicesDaemon

name=pfsense
disk=`pwd`/${name}.qcow2
iso="$HOME/Downloads/OS/pfSense-CE-2.7.0-RELEASE-amd64.iso"

addr="192.168.10.112"

seckey="id_ed25519"

inventory="hosts"
playbook="site.yml"

#ansible_opts="-K"
ansible_opts=""

ansible_opts="$ansible_opts -i ${inventory}"

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
    qemu-img create -f qcow2 $disk 16G
  fi
}

install()
{
  disk

  virt-install \
    --name ${name} \
    --ram 2048 \
    --disk=$disk,bus=virtio \
    --vcpus 2 \
    --os-variant freebsd13.0 \
    --network bridge=br0 \
    --network bridge=br1 \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty
}

help()
{
  usage
}

prepare()
{
  ansible-galaxy collection install community.general
}

key()
{
  ssh-keygen -t ed25519 -N '' -f $seckey -C freebsd
}

connect()
{
  command ssh root@${addr}
}

ssh()
{
  command ssh root@${addr} -i $seckey \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null
}

sftp()
{
  command sftp -i $seckey root@${addr}
}

install_python()
{
  command ssh root@${addr} -i $seckey -- pkg install -y python
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

hosts()
{
  if [ -e "groups.ini" ]; then
    ansible-inventory -i groups.ini --list --yaml > hosts.yml
  fi
}

deploy()
{
  ansible-playbook -i hosts.yml site.yml
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

hosts

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

