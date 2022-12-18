#!/bin/sh

disk=`pwd`/rocky9.qcow2
qemu-img create -f qcow2 $disk 8G

iso=~/Downloads/Rocky-9.0-x86_64-minimal.iso

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


