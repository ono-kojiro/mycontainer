#!/bin/sh

set -e

while [ ! -f /var/run/lightdm/root/:0 ]; do
    echo "Waiting for Xorg..."
    sleep 0.5
done

exec /usr/bin/x11vnc \
    -display :0 \
    -auth /var/run/lightdm/root/:0 \
    -forever -shared -nopw -rfbport 5900 -quiet

