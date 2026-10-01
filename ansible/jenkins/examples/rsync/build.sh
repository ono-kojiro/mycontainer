#!/bin/sh

mkdir -p /home/agent/pcapd
rsync -avz --remove-source-files 192.168.1.52:/home/pcapd/pcapd/* \
  /home/agent/pcapd/

