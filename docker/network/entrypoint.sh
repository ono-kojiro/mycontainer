#!/bin/sh

envsubst < /etc/ldap/ldap.conf.template > /etc/ldap/ldap.conf

envsubst < /etc/sssd/sssd.conf.template > /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf
chmod 0600 /etc/sssd/sssd.conf

MAIN_IF=$(ip -o -4 addr show | awk -v ip="$MAIN_IP" '$4 ~ ip {print $2}')

if [ -z "$MAIN_IF" ]; then
    echo "ERROR: MAIN_IP not found" >&2
    exit 1
fi

ip route del default 2>/dev/null || true
ip route add default via "$GATEWAY" dev "$MAIN_IF"

exec "$@"

