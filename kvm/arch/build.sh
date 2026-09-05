#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

flags=""

name="ArchLinux"
xmlfile="${name}.xml"

help()
{
  usage
}

usage()
{
  cat << EOS
usage : $0 [options] target1 target2 ...

  target:
    dumpxml
    modify
    undefine
    define

    start
EOS

}

all()
{
  deploy
}

clean()
{
  ansible-playbook -i hosts.yml clean.yml
}

hosts()
{
  ansible-inventory -i inventory.yml --list --yaml > hosts.yml
}

#template()
#{
#  disk
#  
#  loader="/usr/share/OVMF/OVMF_CODE_4M.fd"
#  nvram="/var/lib/libvirt/qemu/nvram/ArchLinux_VARS_4M.fd"
#  
#  echo "INFO: generate ${name}.xml"
#  
#  virt-install --print-xml --noreboot \
#  --name "$name" \
#  --memory "$memory" \
#  --vcpus "$vcpus" \
#  --disk=$disk,bus=virtio \
#  --os-variant archlinux \
#  --boot loader=$loader,loader.readonly=yes,loader.type=pflash,nvram=$nvram \
#  --graphics vnc,listen=0.0.0.0,keymap=ja \
#  --console pty,target_type=serial \
#  --boot uefi \
#  --serial pty \
#  > ${name}.xml
#}

dumpxml()
{
  echo "save configuration to $xmlfile"
  virsh dumpxml ${name} > $xmlfile

  if [ ! -e "${xmlfile}.orig" ]; then
    cp -f ${xmlfile} ${xmlfile}.orig
  fi
}

modify()
{
  echo "modify $xmlfile ..."

  # remove secure=yes
  sed -i -e "s|secure='yes' ||" $xmlfile
  
  # remove VARS template for Secure Boot
  sed -i -e "s| template='/usr/share/OVMF/OVMF_VARS_4M.ms.fd'||" $xmlfile

  # use non-secure CODE
  sed -i -e "s|/usr/share/OVMF/OVMF_CODE_4M.ms.fd|/usr/share/OVMF/OVMF_CODE_4M.fd|" $xmlfile

  sed -i -e "/secure-boot/d"   $xmlfile
  sed -i -e "/enrolled-keys/d" $xmlfile
}

undefine()
{
  virsh undefine $name
}

remove()
{
  undefine
}

define()
{
  virsh define $xmlfile
}

shutdown()
{
  virsh destroy ${name}
}

start()
{
  virsh start ${name}
}

install()
{
  ansible-playbook $flags -i hosts.yml -t install site.yml
}

deploy()
{
  ansible-playbook $flags -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook $flags -i hosts.yml -t ${tag} site.yml
}

hosts

args=""
while [ "$#" -ne 0 ]; do
  case $1 in
    -h )
      usage
      exit 1
      ;;
    -v )
      verbose=1
      ;;
    -* )
      flags="$flags $1"
      ;;
    * )
      args="$args $1"
      ;;
  esac
  
  shift
done

if [ -z "$args" ]; then
  help
  exit 1
fi

for arg in $args; do
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $arg
  else
    #echo "ERROR : $arg is not shell function"
    #exit 1
    default $arg
  fi
done

