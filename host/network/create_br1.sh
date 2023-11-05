#!/bin/sh

device="enx9c5322b21d32"

cidr="192.168.10.1/24"
gw="192.168.10.1"
dns="192.168.0.1"

sudo nmcli con add type bridge con-name br1 ifname br1
sudo nmcli con mod br1 bridge.stp no

sudo nmcli con add type ethernet con-name eth1 ifname $device master br1

sudo nmcli con mod br1 \
  ipv4.method manual \
  ipv4.addresses $cidr \
  ipv4.gateway $gw \
  ipv4.dns     $dns

conns="br1"
for conn in $conns; do
  nmcli con | awk '{ print $1 }' | grep -e "^$conn$" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    sudo nmcli con down $conn
  fi
done

conns="br1 eth1"
for conn in $conns; do
  nmcli con | awk '{ print $1 }' | grep -e "^$conn$" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    sudo nmcli con up  $conn
  fi
done

