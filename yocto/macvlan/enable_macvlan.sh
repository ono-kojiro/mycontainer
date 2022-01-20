#!/bin/sh

remote=yocto

scp eth0.network     $remote:/etc/systemd/network/
scp macvlan0.netdev  $remote:/etc/systemd/network/
scp macvlan0.network $remote:/etc/systemd/network/

