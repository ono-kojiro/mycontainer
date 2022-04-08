#!/bin/sh

ansible-playbook -i inventory/hosts tasks/apt/apt_update.yml
