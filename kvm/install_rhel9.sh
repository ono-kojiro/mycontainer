#!/bin/sh

disk=`pwd`/rhel9.qcow2
qemu-img create -f qcow2 $disk 16G

iso=$HOME/Downloads/rhel-baseos-9.0-x86_64-boot.iso

# confirm OS variant with following command
# $ osinfo-query os

virt-install \
  --name rhel9 \
  --ram 4096 \
  --disk=$disk,bus=virtio \
  --vcpus 2 \
  --os-variant rhel9.0 \
  --console pty,target_type=serial \
  --location=$iso \
  --graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja \
  --serial pty

