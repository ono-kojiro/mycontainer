#!/bin/sh

sudo systemctl enable systemd-networkd.service
sudo systemctl enable networkd-dispatcher.service
sudo netplan apply

