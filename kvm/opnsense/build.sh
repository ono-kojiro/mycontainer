#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

# https://wiki.freebsd.org/KubilayKocak/SystemSecurityServicesDaemon

name=opnsense
img="/var/lib/libvirt/images/OPNsense-24.1-serial-amd64.img"
boot="/var/lib/libvirt/images/${name}-boot.qcow2"
disk="/var/lib/libvirt/images/${name}.qcow2"

seckey="id_ed25519"

inventory="hosts"
playbook="site.yml"

#ansible_opts="-K"
ansible_opts=""

ansible_opts="$ansible_opts -i ${inventory}"

if [ "x$LIBVIRT_DEFAULT_URI" = "x" ]; then
  export LIBVIRT_DEFAULT_URI=qemu:///system
fi

all()
{
  help
}

help()
{
  cat - << EOF
usage : $0 target1 target2 ...

target
  all
  help

  disk
  xml

  status
  define
  undefine

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
  # create boot disk from img
  sudo qemu-img convert -f raw -O qcow2 $img $boot
  #qemu-img resize $boot +8G
  
  if [ ! -e "$disk" ]; then
    sudo -- \
      sh -c " \
        qemu-img create -f qcow2 $disk 16G; \
      "
  fi
        
}

xml()
{
  disk

  virt-install \
    --print-xml \
    --name ${name} \
    --ram 2048 \
    --disk path=$boot,bus=virtio \
    --disk path=$disk,bus=virtio \
    --vcpus 4 \
    --os-variant freebsd13.0 \
    --network bridge=ovsbr40,virtualport_type=openvswitch \
    --network bridge=virbr0 \
    --console pty,target_type=serial \
    --nographics \
    --serial pty \
    --autostart \
    --noreboot \
    --boot hd \
    > ${name}.xml
    
    #--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
    #--cdrom $iso \
}

config()
{
  python3 automate.py --name opnsense-base --config config.yml
}

define()
{
  virsh define ${name}.xml
}

detach()
{
  virsh detach-disk --domain $name $boot --persistent --config
}

prepare()
{
  ansible-galaxy collection install community.general
}

key()
{
  ssh-keygen -t ed25519 -N '' -f $seckey -C freebsd
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
      help
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

