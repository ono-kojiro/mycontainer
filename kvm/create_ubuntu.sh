#!/bin/sh

disk=`pwd`/ubuntu.qcow2
qemu-img create -f qcow2 $disk 16G

iso=~/Downloads/ubuntu-18.04.6-live-server-amd64.iso

virt-install \
--name ubuntu \
--ram 4096 \
--disk=$disk,bus=virtio \
--vcpus 4 \
--os-type linux \
--os-variant ubuntu18.04 \
--graphics none \
--console pty,target_type=serial \
--location 'http://jp.archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
--extra-args 'console=ttyS0,115200n8 serial'

#--location 'http://jp.archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
#--graphics vnc,password=vnc,listen=0.0.0.0,keymap=ja 


# インストール終了直後、一旦ホスト側に戻り、ゲストをシャットダウン
# root@dlp:~# virsh shutdown ubuntu1804
# Domain template is being shutdown
# ゲスト領域をマウントしてサービスを有効にする
# root@dlp:~# guestmount -d ubuntu1804 -i /mnt
# root@dlp:~# ln -s /mnt/lib/systemd/system/getty@.service /mnt/etc/systemd/system/getty.target.wants/getty@ttyS0.service
# root@dlp:~# umount /mnt
# 再度起動し、コンソールに接続できればインストール完了
# root@dlp:~# virsh start ubuntu1804 --console

