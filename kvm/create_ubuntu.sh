#!/bin/sh

disk=`pwd`/ubuntu1804.qcow2
qemu-img create -f qcow2 $disk 16G

virt-install \
--name ubuntu1804 \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 2 \
--os-type linux \
--os-variant ubuntu18.04 \
--graphics none \
--console pty,target_type=serial \
--location 'http://jp.archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
--extra-args 'console=ttyS0,115200n8 serial'

#--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja 

