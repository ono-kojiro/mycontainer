#!/bin/sh

ssh-ldap-pubkey add \
  -D cn=Manager,dc=example,dc=com \
  $HOME/.ssh/id_ed25519.pub


