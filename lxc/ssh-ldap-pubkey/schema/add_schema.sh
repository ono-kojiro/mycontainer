#!/bin/sh

sudo cp openssh-lpk.schema /etc/ldap/schema/
ldap-schema-manager -i openssh-lpk.schema --yes



