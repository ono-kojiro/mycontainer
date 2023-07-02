#!/bin/sh

pattern=`cat $HOME/.ssh/id_ed25519.pub`

ssh-ldap-pubkey del \
  -D cn=Manager,dc=example,dc=com "$pattern"




