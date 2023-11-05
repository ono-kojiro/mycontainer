#!/bin/sh

conns="br0 eth0 br1 eth1"

for conn in $conns; do
  nmcli con | awk '{ print $1 }' | grep -e "^$conn$" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "remove $conn"
    sudo nmcli con del $conn
  else
    echo "SKIP: no such connection, $conn"
  fi
done


