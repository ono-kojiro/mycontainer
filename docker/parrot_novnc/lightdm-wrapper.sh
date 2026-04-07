#!/bin/sh

set -e

while [ ! -S /run/dbus/system_bus_socket ]; do
    echo "Waiting for dbus..."
    sleep 0.2
done

exec /usr/sbin/lightdm

