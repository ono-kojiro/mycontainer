#!/bin/sh

envsubst < /etc/ldap/ldap.conf.template > /etc/ldap/ldap.conf

envsubst < /etc/sssd/sssd.conf.template > /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf
chmod 0600 /etc/sssd/sssd.conf

envsubst < /etc/nginx/includes/ssl.conf.template > /etc/nginx/includes/ssl.conf

exec "$@"

