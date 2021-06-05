#!/bin/sh

disk=`pwd`/netbsd8.qcow2
qemu-img create -f qcow2 $disk 16G

iso=`pwd`/NetBSD-8.0-amd64.iso

virt-install \
--name netbsd8 \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 2 \
--os-type bsd \
--os-variant netbsd8.0 \
--graphics none \
--console pty,target_type=serial \
--cdrom=$iso \
--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
--serial pty

#--extra-args 'console=ttyS0,115200n8 serial'


