#!/bin/sh

disk=`pwd`/archlinux.qcow2
qemu-img create -f qcow2 $disk 16G

iso=`pwd`/archlinux-2021.06.01-x86_64.iso

virt-install \
--name archlinux \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 2 \
--os-type linux \
--graphics none \
--console pty,target_type=serial \
--cdrom=$iso \
--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
--serial pty

#--extra-args 'console=ttyS0,115200n8 serial'


