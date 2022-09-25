#!/bin/sh

remote=yocto

cat - << 'EOS' > macvlan0.netdev 
[NetDev]
Name=macvlan0
Kind=macvlan

[MACVLAN]
Mode=bridge
EOS

cat - << 'EOS' > macvlan0.network 
[Match]
Name=macvlan0

[Network]
IPForward=yes
Address=192.168.7.2/24
Gateway=192.168.7.2
#DHCP=yes
DHCP=no
LinkLocalAddressing=no
EOS

cat - << 'EOS' > eth0.network 
[Match]
Name=eth0

[Network]
MACVLAN=macvlan0
LinkLocalAddressing=no
EOS

scp eth0.network     $remote:/etc/systemd/network/
scp macvlan0.netdev  $remote:/etc/systemd/network/
scp macvlan0.network $remote:/etc/systemd/network/

