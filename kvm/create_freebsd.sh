#!/bin/sh

name=freebsd
disk=`pwd`/${name}.qcow2
qemu-img create -f qcow2 $disk 16G

#iso=`pwd`/FreeBSD-13.0-RELEASE-amd64-disc1.iso
iso=~/Downloads/FreeBSD-13.0-RELEASE-amd64-disc1.iso

virt-install \
  --name ${name} \
  --ram 4096 \
  --disk=$disk,bus=virtio \
  --vcpus 2 \
  --os-type bsd \
  --os-variant freebsd11.2 \
  --network network=default --noautoconsole \
  --console pty,target_type=serial \
  --cdrom=$iso \
  --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
  --serial pty

#  --extra-args 'console=ttyS0,115200n8 serial'

