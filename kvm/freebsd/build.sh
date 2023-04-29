#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

# https://wiki.freebsd.org/KubilayKocak/SystemSecurityServicesDaemon

name=freebsd
disk=`pwd`/${name}.qcow2
iso="$HOME/Downloads/FreeBSD-13.1-RELEASE-amd64-disc1.iso"

addr="192.168.122.123"

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
  qemu-img create -f qcow2 $disk 16G
}

key()
{
  ssh-keygen -t ed25519 -N '' -f id_ed25519_freebsd
}

connect()
{
  command ssh root@${addr}
}

ssh()
{
  command ssh root@${addr} -i id_ed25519_freebsd
}

sftp()
{
  command sftp -i id_ed25519_freebsd root@${addr}
}

install_python()
{
  command ssh root@${addr} -i id_ed25519_freebsd -- pkg install -y python
}


debug()
{
  ansible-playbook -i hosts -t sudo site.yml
}

deploy()
{
  # install python39 by hand
  ansible-playbook -i hosts site.yml
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
    --network network=default --noautoconsole \
    --console pty,target_type=serial \
    --cdrom=$iso \
    --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    --serial pty

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
    exit 1
  fi
done

