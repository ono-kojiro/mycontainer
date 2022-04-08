#!/bin/sh

ansible all -i inventory/hosts -m ping
