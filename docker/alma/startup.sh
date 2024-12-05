#!/bin/bash

if [ -e "/usr/sbin/sshd" ]; then
  /usr/sbin/sshd -D &
fi

if [ -e "/usr/sbin/sssd" ]; then
  /usr/sbin/sssd &
fi

#
# https://teratail.com/questions/19382
#
while true ; do
  /bin/bash
done

