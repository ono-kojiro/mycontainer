#!/bin/sh

disk=`pwd`/omnios.qcow2
qemu-img create -f qcow2 $disk 16G

iso=/home/kojiro/Downloads/omnios-r151038k.iso

virt-install \
--name omnios \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 4 \
--os-type solaris \
--os-variant solaris11 \
--console pty,target_type=serial \
--cdrom=$iso \
--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
--serial pty

#--extra-args 'console=ttyS0,115200n8 serial'


