#!/bin/sh

# copy this file to /etc/networkd-dispatcher/routable.d/

ip link add macvlan0 link enp0s25 type macvlan mode bridge

# END

