#!/bin/sh

# RUN THIS SCRIPT LIKE:
# $ sudo pwd
# $ nohup sudo sh enable_macvlan.sh &
#

iface="enp131s0"
macvlan="macvlan0"

addr="192.168.1.72/24"
gateway="192.168.1.1"
dns="192.168.1.1"

nmcli con del $iface

nmcli con add \
    type ethernet \
    conn.id $iface \
    ifname $iface \
    ipv4.method disable \
    ipv6.method disable

nmcli con add \
    type macvlan \
    conn.id $macvlan \
    ifname $macvlan \
    dev $iface \
    mode bridge \
    ipv4.method manual \
    ipv4.addresses $addr \
    ipv4.gateway $gateway \
    ipv4.dns     $dns \
    ipv6.method disable

nmcli con up $iface
nmcli con up $macvlan

reboot

