#!/bin/sh

disk=`pwd`/netbsd.qcow2
qemu-img create -f qcow2 $disk 16G

iso=~/Downloads/NetBSD-9.2-amd64.iso

virt-install \
--name netbsd \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 4 \
--os-type bsd \
--os-variant netbsd8.0 \
--graphics none \
--console pty,target_type=serial \
--cdrom=$iso \
--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
--serial pty

#--extra-args 'console=ttyS0,115200n8 serial'


