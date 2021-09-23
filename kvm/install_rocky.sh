#!/bin/sh

disk=`pwd`/rocky.qcow2
if [ ! -e $disk ]; then
  qemu-img create -f qcow2 $disk 16G
fi

iso=~/Downloads/Rocky-8.4-x86_64-boot.iso

# show list of OS variant
# $ osinfo-query os 

virt-install \
--name rocky \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 2 \
--os-type linux \
--os-variant centos7.0 \
--graphics none \
--console pty,target_type=serial \
--location=$iso \
--extra-args 'console=ttyS0,115200n8 serial'


