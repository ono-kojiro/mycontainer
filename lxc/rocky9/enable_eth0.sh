#!/bin/sh

ip link set eth0 up
ip route replace default via 10.0.3.1
echo 'nameserver 10.0.3.1' > /etc/resolv.conf

