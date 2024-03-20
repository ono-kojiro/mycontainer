#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

# https://wiki.freebsd.org/KubilayKocak/SystemSecurityServicesDaemon

name=opnsense50
disk="/var/lib/libvirt/images/${name}.qcow2"

if [ "x$LIBVIRT_DEFAULT_URI" = "x" ]; then
  export LIBVIRT_DEFAULT_URI=qemu:///system
fi

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

dump()
{
  virsh dumpxml $name > ${name}.xml
}

clone()
{
  virt-clone --original opnsense-base --auto-clone --name $name
}

define()
{
  virsh define ${name}.xml
}

detach()
{
  virsh detach-disk --domain $name $boot --persistent --config
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

undefine()
{
  virsh undefine $name
}

destroy()
{
  virsh destroy  $name
}

list()
{
  virsh list --all
}

netlist()
{
  virsh net-list --all
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

