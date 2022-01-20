#!/bin/sh

sh destroy_lxc.sh

sh create_lxc.sh -t busybox -n mybusy -a 192.168.7.5
sh create_lxc.sh -t sshd    -n mysshd -a 192.168.7.6


