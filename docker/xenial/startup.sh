#!/bin/bash

rm -rf /var/run/sssd.pid

service ssh start
service sssd start

#
# https://teratail.com/questions/19382
#
while true ; do
  /bin/bash
done

