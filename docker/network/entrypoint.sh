#!/bin/sh

envsubst < /etc/ldap/ldap.conf.template > /etc/ldap/ldap.conf

envsubst < /etc/sssd/sssd.conf.template > /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf
chmod 0600 /etc/sssd/sssd.conf

MAIN_IF=$(ip -o -4 addr show \
    | awk '!/127\.0\.0\.1/ && !/172\.31\.0\./ {print $2}' \
    | head -n 1)

MAIN_GW=$(ip -o -4 addr show "$MAIN_IF" \
    | awk '{print $4}' \
    | sed 's/\/.*//' \
    | awk -F. '{print $1"."$2"."$3".1"}')

ip route del default 2>/dev/null || true
ip route add default via "$MAIN_GW" dev "$MAIN_IF"

exec "$@"

