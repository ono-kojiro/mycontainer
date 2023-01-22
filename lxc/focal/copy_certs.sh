#!/bin/sh

cp -f myca.pem  roles/certs/templates/
cp -f focal.crt roles/certs/templates/
cp -f focal.key roles/certs/templates/
ansible-playbook -i hosts --tags certs site.yml

