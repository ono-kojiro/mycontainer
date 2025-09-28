#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

# https://wiki.freebsd.org/KubilayKocak/SystemSecurityServicesDaemon

name=freebsd
disk=`pwd`/${name}.qcow2
#iso="$HOME/Downloads/FreeBSD-13.1-RELEASE-amd64-disc1.iso"
iso="$HOME/Downloads/FreeBSD-13.2-RELEASE-amd64-dvd1.iso"

addr="192.168.10.111"

seckey="id_ed25519"

inventory="hosts"
playbook="site.yml"

flags=""

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
  qemu-img create -f qcow2 $disk 16G
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



install()
{
  virt-install \
    --name ${name} \
    --ram 4096 \
    --disk=$disk,bus=virtio \
    --vcpus 2 \
    --os-variant freebsd13.0 \
    --network bridge=br0 \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty

#    --network network=default --noautoconsole \
#  --extra-args 'console=ttyS0,115200n8 serial'
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
  ansible-inventory -i template.yml --list --yaml > hosts.yml
}

deploy()
{
  ansible-playbook ${flags} -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook ${flags} -i hosts.yml -t ${tag} site.yml
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
    -* )
      flags="$flags $1"
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
  fi
done

