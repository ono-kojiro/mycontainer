#!/bin/sh

cp -f focal.crt roles/slapd/templates/
cp -f focal.key roles/slapd/templates/
ansible-playbook -i hosts --tags slapd site.yml

