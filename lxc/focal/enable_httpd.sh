#!/bin/sh

ansible-playbook -i hosts --tags httpd site.yml

