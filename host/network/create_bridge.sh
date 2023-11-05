#!/bin/sh

device="enp0s31f6"

cidr="192.168.0.98/24"
gw="192.168.0.1"
dns="192.168.0.1"

sudo nmcli con add type bridge con-name br0 ifname br0
sudo nmcli con mod br0 bridge.stp no

sudo nmcli con add type ethernet con-name eth0 ifname $device master br0

sudo nmcli con mod br0 \
  ipv4.method manual \
  ipv4.addresses $cidr \
  ipv4.gateway $gw \
  ipv4.dns     $dns

conns="br0"
for conn in $conns; do
  nmcli con | awk '{ print $1 }' | grep -e "^$conn$" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    sudo nmcli con down $conn
  fi
done

conns="br0 eth0"
for conn in $conns; do
  nmcli con | awk '{ print $1 }' | grep -e "^$conn$" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    sudo nmcli con up  $conn
  fi
done

