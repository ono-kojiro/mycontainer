#!/bin/sh

set -e

if [ -n "$VNC_PASSWORD" ]; then
    echo "Setting VNC password..."
    mkdir -p /root/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
    chmod 600 /root/.vnc/passwd
fi

exec "$@"

