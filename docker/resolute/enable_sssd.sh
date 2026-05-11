#!/bin/sh

# Configure SSSD.
chmod 600 /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf
sed 's|-D -f|-D|' -i /etc/default/sssd
pam-auth-update --enable mkhomedir

sed -i -e 's|^#\(AuthorizedKeysCommand\)\s\+.\+|\1 /usr/bin/sss_ssh_authorizedkeys|' /etc/ssh/sshd_config
sed -i -e 's|^#\(AuthorizedKeysCommandUser\)\s\+\(.\+\)|\1 \2|' /etc/ssh/sshd_config

