#!/bin/sh

disk=`pwd`/centos7.qcow2
qemu-img create -f qcow2 $disk 16G

iso=`pwd`/CentOS-7-x86_64-Minimal-2009.iso

virt-install \
--name centos7 \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 2 \
--os-type linux \
--os-variant centos7.0 \
--graphics none \
--console pty,target_type=serial \
--location=$iso \
--extra-args 'console=ttyS0,115200n8 serial'


