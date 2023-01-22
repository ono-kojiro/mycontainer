#!/bin/sh

ansible-playbook -i hosts --tags slapd site.yml

