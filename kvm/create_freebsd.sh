#!/bin/sh

disk=`pwd`/freebsd13.qcow2
qemu-img create -f qcow2 $disk 16G

iso=`pwd`/FreeBSD-13.0-RELEASE-amd64-bootonly.iso

virt-install \
--name freebsd13 \
--ram 2048 \
--disk=$disk,bus=virtio \
--vcpus 2 \
--console pty,target_type=serial \
--cdrom=$iso \
--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
--serial pty

#--extra-args 'console=ttyS0,115200n8 serial'


